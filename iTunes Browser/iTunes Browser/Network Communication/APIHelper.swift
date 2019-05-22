//
//  APIHelper.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 5/5/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

typealias DictionaryResponseBlock = ([String : Any]?) -> Void
typealias DataResponseBlock = (Data?) -> Void

class APIHelper {
    
    private let baseURLString = "https://itunes.apple.com"
    
    private let session = URLSession.init(configuration: URLSessionConfiguration.default)
    
    // MARK: - Base methods
    
    private func createRequest(withPath path: String, method: HTTPMethod, parameters: [String : Any]?) -> URLRequest {
        var URLPath = path
        
        if let params = parameters {
            var paramsString = "?"
            var isFirstParam = true
            
            params.forEach {
                var (key, value) = $0
                
                if let stringValue = value as? String, let percentEncodedValue = stringValue.stringByAddingPercentEncodingToData() {
                    value = percentEncodedValue
                }
                
                if isFirstParam {
                    isFirstParam = false
                } else {
                    paramsString.append("&")
                }
                
                paramsString.append(key + "=\(value)")
            }
            
            URLPath.append(paramsString)
        }
        
        let requestURL = URL(string: baseURLString + "/" + URLPath)
        var request = URLRequest(url: requestURL!)
        
        request.httpMethod = method.rawValue
        
        return request
    }
    
    private func printError(forRequest request: URLRequest, response: URLResponse?, data: Data?, error: Error?) {
        print("URL: \(response?.url ?? request.url!) Status code: \((response as? HTTPURLResponse)?.statusCode ?? -1) \(error?.localizedDescription ?? "Error")")
        
        if let responseData = data {
            if let responseObject = try? JSONSerialization.jsonObject(with: responseData, options: []) {
                print(responseObject)
            }
        }
    }
    
    private func processDataDictionaryResponse(withData data: Data?, request: URLRequest, response: URLResponse?, error: Error?, completionHandler: DictionaryResponseBlock) {
        let statusCode: Int = (response as? HTTPURLResponse)?.statusCode ?? -1
        
        var resultDict: [String : Any]? = nil
        
        if error == nil && statusCode == 200 {
            if let responseData = data {
                if let dict = try? JSONSerialization.jsonObject(with: responseData, options: []) {
                    resultDict = dict as? [String : Any]
                }
            }
        } else {
            printError(forRequest: request, response: response, data: data, error: error)
        }
        
        completionHandler(resultDict);
    }
    
    private func processDataResponse(with data: Data?, request: URLRequest, response: URLResponse?, error: Error?, completionHandler: DataResponseBlock) {
        let statusCode: Int = (response as? HTTPURLResponse)?.statusCode ?? -1

        var resultData: Data? = nil
        
        if error == nil && statusCode == 200 {
            resultData = data
        } else {
            printError(forRequest: request, response: response, data: data, error: error)
        }
        
        completionHandler(resultData);
    }

    // MARK: - Search request
    
    func searchItems(of type: String, with searchString: String, completionHandler: @escaping DictionaryResponseBlock) {
        let parametersDict: [String : Any] = ["media": type, "term": searchString]

        let request = createRequest(withPath: "search", method: .GET, parameters: parametersDict)
        
        let dataTask = session.dataTask(with: request) { [weak self] (data, response, error) in
            self?.processDataDictionaryResponse(withData: data, request: request, response: response, error: error, completionHandler: completionHandler)
        }
        
        dataTask.resume()
    }

    // MARK: - External resource request
    
    func externalResourceGetData(with url: String, completionHandler: @escaping DataResponseBlock) -> Void {
        guard let requestURL = URL(string: url) else {
            completionHandler(nil)
            return
        }
        
        let request = URLRequest(url: requestURL)
        
        let dataTask = session.dataTask(with: request) { [weak self] (data, response, error) in
            self?.processDataResponse(with: data, request: request, response: response, error: error, completionHandler: completionHandler)
        }
        
        dataTask.resume()
    }
}
