import SwiftUI
import UIKit

@MainActor
final class BenchImageViewModel: ObservableObject {
    // UI state
    @Published var host: String = ""
    @Published var selectedImageLabel: String = "SkyLine"
    @Published var selectedFilter: String = "Cartoonizer"
    @Published var selectedSize: String = "8MP"
    @Published var selectedLocal: String = "Local"
    @Published var benchmarkMode: Bool = false

    @Published var statusText: String = "Status: No activity"
    @Published var sizeText: String = "Resolution/Photo: -"
    @Published var execText: String = "Execution Time: 0 ms"
    @Published var resultImage: UIImage? = nil

    @Published var isComputing: Bool = false
    @Published var showUnsupportedAlert: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var unsupportedMessage: String = ""
    @Published var errorMessage: String = "Status: Error during the transmission!"
    
    // Para o teste de acesso às imagens
    @Published var testResults: String = ""
    @Published var showTestResults: Bool = false

    // pickers data
    let images: [String]  = ["FAB Show", "Cidade", "SkyLine"]
    let filters: [String] = ["Cartoonizer", "Benchmark", "Blur", "Sharpen", "GreyScale", "Original"]
    let sizes: [String]   = ["All", "0.3MP", "1MP", "2MP", "4MP", "8MP"]
    let locals: [String]  = ["Local"] // somente local

    init() {
        selectedImageLabel = "SkyLine"
        selectedSize = "8MP"
        recomputeLabels()
        // não carregamos aqui para evitar tocar em bundle antes da cena montar;
        // chame showInitialImage() do ContentView (via .task)
    }

    // === EXIBIR UMA IMAGEM ASSIM QUE ABRIR ===
    func showInitialImage() async {
        do {
            let name = fileNameFor(label: selectedImageLabel, size: selectedSize)
            let ui = try loadUIImageFromBundle(fileName: name, size: selectedSize)
            resultImage = ui
            statusText = "Status: Image loaded"
            execText = "Execution Time: 0 ms"
            recomputeLabels()
        } catch {
            statusText = "Status: Image not found"
            resultImage = nil
        }
    }

    // ====== AÇÃO DO BOTÃO ======
    func computeTapped() {
        isComputing = true
        statusText = "Status: Submitting Task"
        resultImage = nil
        execText = "Execution Time: 0 ms"

        if (selectedFilter == "Cartoonizer" || selectedFilter == "Benchmark"),
           (selectedSize == "8MP" || selectedSize == "4MP") {
            unsupportedMessage = "Device does not support the Cartoonizer, VMSize minimal recommended is 128MB"
            showUnsupportedAlert = true
            isComputing = false
            statusText = "Status: Previous request does not support Filter!"
            return
        }

        Task { await runLocalFilterOnce() } // SOMENTE LOCAL
    }

    // ====== EXECUTA O FILTRO LOCAL (sem gRPC) ======
    private func runLocalFilterOnce() async {
        do {
            statusText = "Status: Processing"

            // usa a nova convenção de nomes com prefixo de tamanho
            let fileName = fileNameFor(label: selectedImageLabel, size: selectedSize)
            let ui = try loadUIImageFromBundle(fileName: fileName, size: selectedSize)

            guard let jpg = ui.jpegData(compressionQuality: 0.95) else {
                throw NSError(domain: "BenchImage", code: -11, userInfo: [NSLocalizedDescriptionKey: "Falha ao gerar JPEG"])
            }
            var raw = try ImageUtils.decodeJpegToRaw(jpg)

            let t0 = Date().timeIntervalSince1970
            let filter = ImageFilter()

            switch selectedFilter {
            case "GreyScale":
                raw = filter.greyScaleImage(&raw)
            case "Cartoonizer":
                raw = filter.cartoonizerImage(&raw)
            case "Blur":
                let k: [[Double]] = [[1,1,1],[1,1,1],[1,1,1]]
                raw = filter.filterApply(&raw, k, 1.0/9.0, 0.0)
            case "Sharpen":
                let k: [[Double]] = [[ 0,-1, 0],
                                     [-1, 5,-1],
                                     [ 0,-1, 0]]
                raw = filter.filterApply(&raw, k, 1.0, 0.0)
            case "Original":
                break
            case "Benchmark":
                unsupportedMessage = "Benchmark somente no modo benchmark real."
                showUnsupportedAlert = true
                isComputing = false
                statusText = "Status: Previous request does not support Filter!"
                return
            default:
                break
            }

            let dt = Int((Date().timeIntervalSince1970 - t0) * 1000.0)
            let outUI = raw.toUIImage() ?? ui

            resultImage = outUI
            statusText = "Status: Local processing finished"
            execText = "Execution Time: \(dt) ms"
            recomputeLabels()
            isComputing = false

        } catch {
            statusText = errorMessage
            isComputing = false
            showErrorAlert = true
        }
    }

    // ====== UI HELPERS ======
    func recomputeLabels() {
        let sizeShow = (selectedFilter == "Benchmark") ? "All" : selectedSize
        sizeText = "Resolution/Photo: \(sizeShow)/\(selectedImageLabel)"
    }

    // base (sem prefixo) para cada rótulo
    private func baseName(for label: String) -> String {
        switch label {
        case "FAB Show": return "img1.jpg"
        case "Cidade":   return "img4.jpg"
        case "SkyLine":  return "img5.jpg"
        default:         return "img5.jpg"
        }
    }

    // prefixo por tamanho
    private func sizePrefix(_ size: String) -> String {
        switch size {
        case "0.3MP": return "03"
        case "1MP":   return "1"
        case "2MP":   return "2"
        case "4MP":   return "4"
        case "8MP":   return "8"
        default:      return "1"
        }
    }

    // nome final do arquivo - os arquivos reais não têm prefixo
    func fileNameFor(label: String, size: String) -> String {
        baseName(for: label)
    }

    // ====== BUNDLE LOADER (pasta images/<size>) ======
    func sizeToPath(_ size: String) -> String {
        switch size {
        case "8MP":   return "images/8mp"
        case "4MP":   return "images/4mp"
        case "2MP":   return "images/2mp"
        case "1MP":   return "images/1mp"
        case "0.3MP": return "images/0_3mp"
        default:      return "images/1mp"
        }
    }

    func loadUIImageFromBundle(fileName: String, size: String) throws -> UIImage {
        let subdir = sizeToPath(size)
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: subdir),
              let data = try? Data(contentsOf: url),
              let ui = UIImage(data: data)
        else {
            throw NSError(domain: "BenchImage", code: -10,
                          userInfo: [NSLocalizedDescriptionKey: "Nao achei \(fileName) em \(subdir)"])
        }
        return ui
    }
    
    // ====== EXECUTAR TESTE DE ACESSO ÀS IMAGENS ======
    func runImageAccessTest() {
        testResults = testImageAccess()
        showTestResults = true
    }
    
    // ====== FUNÇÃO DE TESTE PARA VERIFICAR ACESSO ÀS IMAGENS ======
    private func testImageAccess() -> String {
        var results: [String] = []
        results.append("=== TESTE DE ACESSO ÀS IMAGENS ===")
        
        // Testa todas as combinações de tamanho e imagem
        let testSizes = ["0.3MP", "1MP", "2MP", "4MP", "8MP"]
        let testImages = ["FAB Show", "Cidade", "SkyLine"]
        
        for size in testSizes {
            results.append("\n--- Testando tamanho: \(size) ---")
            let subdir = sizeToPath(size)
            results.append("Pasta: \(subdir)")
            
            for imageLabel in testImages {
                let fileName = fileNameFor(label: imageLabel, size: size)
                results.append("Arquivo: \(fileName)")
                
                do {
                    let ui = try loadUIImageFromBundle(fileName: fileName, size: size)
                    results.append("✅ SUCESSO: \(fileName) - Tamanho: \(ui.size.width)x\(ui.size.height)")
                } catch {
                    results.append("❌ ERRO: \(fileName) - \(error.localizedDescription)")
                }
            }
        }
        
        // Testa se consegue listar arquivos no bundle
        results.append("\n--- Testando listagem de arquivos no bundle ---")
        for size in testSizes {
            let subdir = sizeToPath(size)
            if let bundleURL = Bundle.main.url(forResource: nil, withExtension: nil, subdirectory: subdir) {
                do {
                    let files = try FileManager.default.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)
                    results.append("Pasta \(subdir): \(files.count) arquivos encontrados")
                    for file in files {
                        results.append("  - \(file.lastPathComponent)")
                    }
                } catch {
                    results.append("❌ Erro ao listar \(subdir): \(error.localizedDescription)")
                }
            } else {
                results.append("❌ Pasta \(subdir) não encontrada no bundle")
            }
        }
        
        return results.joined(separator: "\n")
    }
}
