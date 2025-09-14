import Foundation

class HTTPSClient
{
    let clientHeaders: Dictionary<String, String>
    
    init(clientHeaders: Dictionary<String, String> = [:]) {
        self.clientHeaders = clientHeaders
                
    }
    
    func get(
        url: URL,
        onComplete: @escaping @Sendable (HTTPURLResponse, Foundation.Data?) -> Void = HTTPSClient.defaultOnComplete,
        onError: @escaping @Sendable (Error) -> Void = HTTPSClient.defaultOnError
    ) {
        request(url: url, method: "GET", onComplete: onComplete, onError: onError)
    }

    func put(
        url: URL, body: Foundation.Data? = nil,
        onComplete: @escaping @Sendable (HTTPURLResponse, Foundation.Data?) -> Void = HTTPSClient.defaultOnComplete,
        onError: @escaping @Sendable(Error) -> Void = HTTPSClient.defaultOnError
    ) {
        request(url: url, method: "PUT", body: body, onComplete: onComplete, onError: onError)
    }
    
    func post(
        url: URL, body: Foundation.Data?,
        onComplete: @escaping @Sendable (HTTPURLResponse, Foundation.Data?) -> Void = HTTPSClient.defaultOnComplete,
        onError: @escaping @Sendable (Error) -> Void = HTTPSClient.defaultOnError
    ) {
        request(url: url, method: "POST", body: body, onComplete: onComplete, onError: onError)
    }
    
    func post(
        url: URL,
        bodyString: String,
        onComplete: @escaping @Sendable (HTTPURLResponse, Foundation.Data?) -> Void = HTTPSClient.defaultOnComplete,
        onError: @escaping @Sendable (Error) -> Void = HTTPSClient.defaultOnError
    ) {
        post(url: url, body: bodyString.data(using: .utf8), onComplete: onComplete, onError: onError)
    }
    
    @Sendable private static func defaultOnError(_ err: Error) {
        print("Got error: \(err)")
    }
    
    @Sendable private static func defaultOnComplete(_ response: HTTPURLResponse, _ data: Foundation.Data?) {
        //print("Got response \(response.statusCode)")
        //print("Got headers: \(response.allHeaderFields)")
        if let data = data {
            print("DATA", String(decoding: data, as: UTF8.self))
        }
    }
    
    func request(
        url: URL, method: String,
        body: Foundation.Data? = nil,
        onComplete: @escaping @Sendable (HTTPURLResponse, Foundation.Data?) -> Void = HTTPSClient.defaultOnComplete,
        onError: @escaping @Sendable (Error) -> Void = HTTPSClient.defaultOnError
    ) {
        print("Making \(method) request to \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let body = body {
            request.setValue("\(String(describing: body.count))", forHTTPHeaderField: "Content-Length")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        for (headerName, headerValue) in self.clientHeaders {
            request.setValue(headerValue, forHTTPHeaderField: headerName)
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                onError(error!)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                fatalError("Could not cast response to HTTPURLResponse: \(String(describing: response))")
            }
            onComplete(httpResponse, data)
        }
        
        task.resume()
    }
}

