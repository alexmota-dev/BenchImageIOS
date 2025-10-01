//
//  BenchImageIOSTests.swift
//  BenchImageIOSTests
//
//  Created by Alex Mota on 22/09/25.
//

import Testing
import UIKit
@testable import BenchImageIOS

struct BenchImageIOSTests {

    @Test func testImageAccess() async throws {
        let viewModel = BenchImageViewModel()
        
        // Testa todas as combinações de tamanho e imagem
        let testSizes = ["0.3MP", "1MP", "2MP", "4MP", "8MP"]
        let testImages = ["FAB Show", "Cidade", "SkyLine"]
        
        var successCount = 0
        var totalTests = 0
        
        for size in testSizes {
            for imageLabel in testImages {
                totalTests += 1
                let fileName = viewModel.fileNameFor(label: imageLabel, size: size)
                let subdir = viewModel.sizeToPath(size)
                
                do {
                    let ui = try viewModel.loadUIImageFromBundle(fileName: fileName, size: size)
                    #expect(ui.size.width > 0)
                    #expect(ui.size.height > 0)
                    successCount += 1
                    print("✅ SUCESSO: \(fileName) em \(subdir) - Tamanho: \(ui.size.width)x\(ui.size.height)")
                } catch {
                    print("❌ ERRO: \(fileName) em \(subdir) - \(error.localizedDescription)")
                }
            }
        }
        
        // Verifica se pelo menos 80% dos testes passaram
        let successRate = Double(successCount) / Double(totalTests)
        print("Taxa de sucesso: \(Int(successRate * 100))% (\(successCount)/\(totalTests))")
        #expect(successRate >= 0.8, "Pelo menos 80% das imagens devem ser acessíveis")
    }
    
    @Test func testBundleStructure() async throws {
        let viewModel = BenchImageViewModel()
        let testSizes = ["0.3MP", "1MP", "2MP", "4MP", "8MP"]
        
        for size in testSizes {
            let subdir = viewModel.sizeToPath(size)
            let bundleURL = Bundle.main.url(forResource: nil, withExtension: nil, subdirectory: subdir)
            
            #expect(bundleURL != nil, "Pasta \(subdir) deve existir no bundle")
            
            if let bundleURL = bundleURL {
                let files = try FileManager.default.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)
                #expect(files.count >= 3, "Pasta \(subdir) deve ter pelo menos 3 arquivos")
                print("Pasta \(subdir): \(files.count) arquivos encontrados")
                for file in files {
                    print("  - \(file.lastPathComponent)")
                }
            }
        }
    }
    
    @Test func testSpecificImageFiles() async throws {
        let viewModel = BenchImageViewModel()
        
        // Testa arquivos específicos que sabemos que existem
        let testCases = [
            ("0.3MP", "FAB Show", "img1.jpg"),
            ("0.3MP", "Cidade", "img4.jpg"),
            ("0.3MP", "SkyLine", "img5.jpg"),
            ("1MP", "FAB Show", "img1.jpg"),
            ("8MP", "SkyLine", "img5.jpg")
        ]
        
        for (size, imageLabel, expectedFileName) in testCases {
            let fileName = viewModel.fileNameFor(label: imageLabel, size: size)
            #expect(fileName == expectedFileName, "Nome do arquivo deve ser \(expectedFileName)")
            
            let ui = try viewModel.loadUIImageFromBundle(fileName: fileName, size: size)
            #expect(ui.size.width > 0)
            #expect(ui.size.height > 0)
            print("✅ \(fileName) em \(size): \(ui.size.width)x\(ui.size.height)")
        }
    }

}
