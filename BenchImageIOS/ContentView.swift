import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: BenchImageViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hostField
                statusSection
                statusSection
                resultImageSection
                labelsRow1
                pickersRow1
                labelsRow2
                pickersRow2
                computeButtonRow
                testButtonRow
                benchmarkToggle
            }
            .padding(16)
        }
        .background(Color(UIColor.systemBackground))
        // se estiver no iOS 17+, use a forma nova consolidada — senão, pode manter os três .onChange antigos
        .onChange(of: viewModel.selectedFilter, initial: false) { _, _ in
            viewModel.recomputeLabels()
        }
        .onChange(of: viewModel.selectedSize, initial: false) { _, _ in
            viewModel.recomputeLabels()
        }
        .onChange(of: viewModel.selectedImageLabel, initial: false) { _, _ in
            viewModel.recomputeLabels()
        }
        .alert("Limited device!", isPresented: $viewModel.showUnsupportedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.unsupportedMessage)
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Teste de Acesso às Imagens", isPresented: $viewModel.showTestResults) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.testResults)
        }
    }

    // MARK: - Subviews / Helpers

    private var hostField: some View {
        TextField("Enter Host", text: $viewModel.host)
            .textFieldStyle(.roundedBorder)
            .font(.system(size: 18))
            .disableAutocorrection(true)
            .textInputAutocapitalization(.never)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.execText)
                .font(.system(size: 18, weight: .semibold))
            Text(viewModel.sizeText)
                .font(.system(size: 18))
            Text(viewModel.statusText)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var resultImageSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .frame(maxWidth: .infinity, minHeight: 220)

            if let img = viewModel.resultImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(6)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                    Text("No image")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var labelsRow1: some View {
        HStack {
            Text("Image")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            Spacer()
            Text("Filter")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
    }

    private var pickersRow1: some View {
        HStack(spacing: 12) {
            Picker("Image", selection: $viewModel.selectedImageLabel) {
                ForEach(viewModel.images, id: \.self) { item in
                    Text(item)
                }
            }
            .pickerStyle(.menu)

            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(viewModel.filters, id: \.self) { item in
                    Text(item)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var labelsRow2: some View {
        HStack {
            Text("Resolution")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            Spacer()
            Text("Processing Type")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
    }

    private var pickersRow2: some View {
        HStack(spacing: 12) {
            Picker("Resolution", selection: $viewModel.selectedSize) {
                ForEach(viewModel.sizes, id: \.self) { item in
                    Text(item)
                }
            }
            .pickerStyle(.menu)
            .disabled(viewModel.selectedFilter == "Benchmark")

            Picker("Processing", selection: $viewModel.selectedLocal) {
                ForEach(viewModel.locals, id: \.self) { item in
                    Text(item)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var computeButtonRow: some View {
        HStack {
            Spacer()
            Button {
                viewModel.computeTapped()
            } label: {
                Text(viewModel.isComputing ? "Processing" : "COMPUTE")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: 220)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isComputing)
            Spacer()
        }
    }

    private var testButtonRow: some View {
        HStack {
            Spacer()
            Button {
                viewModel.runImageAccessTest()
            } label: {
                Text("TESTAR ACESSO ÀS IMAGENS")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: 250)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.blue)
            Spacer()
        }
    }

    private var benchmarkToggle: some View {
        Toggle("Execute Benchmark Mode?", isOn: $viewModel.benchmarkMode)
            .font(.system(size: 18))
    }
}
