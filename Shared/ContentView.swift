//
//  ContentView.swift
//  Shared
//
//  Created by Dmitry Boiadji on 13.08.2022.
//

import SwiftUI

struct ContentView: View {
    
    @State var temperature = "... C°";
    
    var body: some View {
        
        Text(temperature)
            .font(.title)
            .foregroundColor(.green)
            .padding()
            .onAppear(perform: fetchAPI)
        
        Button(action: fetchAPI) {
            Label("Refresh", systemImage: "repeat.circle")
        }
    }
    
    
    
    func fetchAPI() {
        let url = URL(string: "https://prometheus.url/api/v1/query?query=temp_celsius")!
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url) { data, response, error in
            guard let data = data else { print(error!); return }
            do {
                let response = try JSONDecoder().decode(Prometheus.self, from: data)
                
                // parsing prometheus api standart metric
                let temp = response.data.result[0].value[1]
                let s = String(describing: temp)
                var modified = s.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "string(", with: "").replacingOccurrences(of: ")", with: "");
                modified += " C°"
                
            
                DispatchQueue.main.async {
                    self.temperature = modified
                }
                return
                
                
            } catch {
                print(error)
            }
        }
        dataTask.resume()
        
    }
    
    
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct Prometheus: Decodable {
    var data: DataStructure
    var status: String
}


struct DataStructure: Decodable {
    var result: [ResultStructure]
    var resultType: String
}

struct ResultStructure: Decodable {
    let value: [Value]
    var metric: MetricStructure
    
}

struct MetricStructure: Decodable {
    var __name__: String
    var job: String
    var sensor: String
}

enum Value: Codable {
    case double(Double)
    case string(String)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Double.self) {
            self = .double(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        throw DecodingError.typeMismatch(Value.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for Value"))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .double(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        }
    }
}
