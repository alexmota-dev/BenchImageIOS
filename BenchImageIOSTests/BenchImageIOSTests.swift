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

    @Test func testSimpleImageAccess() async throws {
        // Teste simples e rápido
        let viewModel = await BenchImageViewModel()
        
        // Testa apenas uma combinação para verificar se funciona
        let fileName = await viewModel.fileNameFor(label: "FAB Show", size: "0.3MP")
        let subdir = await viewModel.sizeToPath("0.3MP")
        
        print("Testando: \(fileName) em \(subdir)")
        
        do {
            let ui = try await viewModel.loadUIImageFromBundle(fileName: fileName, size: "0.3MP")
            #expect(ui.size.width > 0)
            #expect(ui.size.height > 0)
            print("✅ Sucesso: \(fileName) (\(Int(ui.size.width))x\(Int(ui.size.height)))")
        } catch {
            print("❌ Erro: \(fileName) - \(error.localizedDescription)")
            throw error
        }
    }
    
    @Test func testBundleExists() async throws {
        // Teste simples para verificar se o bundle existe
        let bundleURL = Bundle.main.url(forResource: nil, withExtension: nil, subdirectory: "images/0_3mp")
        #expect(bundleURL != nil, "Pasta images/0_3mp deve existir no bundle")
        
        if let bundleURL = bundleURL {
            let files = try FileManager.default.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)
            print("Arquivos encontrados em 0_3mp: \(files.count)")
            for file in files {
                print("  - \(file.lastPathComponent)")
            }
            #expect(files.count >= 3, "Pasta deve ter pelo menos 3 arquivos")
        }
    }

}