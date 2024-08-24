//
// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/RGU/blob/main/LICENSE.
//

import SwiftUI
import UniformTypeIdentifiers

// FileDocument for the save solution
struct SolutionFile: FileDocument {
    var data = Data()
    
    init(configuration: ReadConfiguration) throws {
        if let newData = configuration.file.regularFileContents {
            data = newData
        }
    }
    
    init(initialData: Data = Data()) {
        self.data = initialData
    }
    
    static var readableContentTypes = [UTType.data]
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
    
    static var writableContentTypes = [UTType.data]
}

struct ContentView: View {
    
    enum SolverState {
        case readyToSolve
        case solving
        case solutionReady
    }
    
    // Overall state of the UI
    @State private var solverState: SolverState = .readyToSolve
    
    // Progress reported to the user
    @State private var progress = 0.0
    @State private var progressText = "Ready to solve"
    @State private var subProgress = 0.0
    @State private var subProgressText = ""
    
    // Used to scale the progress bars.
    static private let allStates = SafeCounts.all.sorted(by: >)
    static private let progressTotal = Double(allStates.count)
    static private let subProgressTotal = -log10(Solver.threshold)
    
    // Task performing the solution.
    @State private var task: Task<Void, Never>?
    
    // Expected win pct. of the first player.
    @State private var winPct: Float = 0.0
    
    // Solution to be exported.
    @State private var solution: SolutionFile?
    @State private var showingExporter = false
    @State private var writeError = ""
    @State private var showingWriteError = false
    
    var body: some View {
        VStack {
            ProgressView(progressText, value: progress, total: Self.progressTotal)
            ProgressView(subProgressText, value: subProgress, total: Self.subProgressTotal)
            HStack(spacing: 20.0) {
                Button("Solve") {
                    setSolverState(.solving)
                    task = Task {
                        let posVals = await Solver.solve(reportProgress: reportProgress)
                        if Task.isCancelled {
                           setSolverState(.readyToSolve)
                        } else {
                            winPct = 100.0 * posVals[.init()]
                            solution = SolutionFile(initialData: posVals.encode())
                            setSolverState(.solutionReady)
                        }
                    }
                }
                .disabled(solverState != .readyToSolve)
                Button("Export") {
                    showingExporter = true
                }
                .disabled(solverState != .solutionReady)
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: solution,
            contentType: .data,
            defaultFilename: "rguSolution.data"
            
        ) { result in
            switch result {
            case .success:
                solution = nil
                setSolverState(.readyToSolve)
            case .failure(let error):
                writeError = error.localizedDescription
                showingWriteError = true
            }
        }
        .alert("Error Exporting File", isPresented: $showingWriteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(writeError)
        }
        .padding()
    }
    
    // Update the progress display when solver state changes.
    func setSolverState(_ newState: SolverState) {
        solverState = newState
        switch newState {
        case .readyToSolve:
            progressText = "Ready to solve"
            progress = 0.0
            subProgressText = ""
            subProgress = 0.0
            
        case .solving:
            progressText = "Building positions ..."
            progress = 0.0
            subProgressText = ""
            subProgress = 0.0
            
        case .solutionReady:
            progressText = String(
                format: "Solution ready: first player win pct. = %.3f%%",
                winPct
            )
            progress = Self.progressTotal
            subProgressText = ""
            subProgress = Self.progressTotal
        }
    }
    
    func reportProgress(report: Solver.Progress) {
        switch report {
        case .buildingGraph(let state):
            progressText = String(format: "State: (%d, %d)", state.hi, state.lo)
            progress = Double(Self.allStates.firstIndex(of: state)!)
            subProgressText = "Building graph ..."
            subProgress = 0.0
            
        case .optimzing(let iteration, let delta):
            subProgressText = String(format: "Iteration: %d", iteration)
            subProgress = delta > 0 ? min(-log10(delta), Self.subProgressTotal) : 1.0
        }
    }
}

#Preview {
    ContentView()
}
