import Foundation
import When

func attempt(_ request: @escaping () -> NetworkPromise) -> NetworkPromise {
  return attempt(request: request)
}

func attempt(request: @escaping () -> NetworkPromise,
             maximumAttempts: Int = 5,
             retryInterval: TimeInterval = 0.2,
             queue: DispatchQueue = .main) -> NetworkPromise
{
  let promise = NetworkPromise()
  
  var attempts = 0
  var errors = [Error]()
  
  func attempt() {
    request()
      .done { response in
        promise.resolve(response)
      }
      .fail { error in
        if attempts < maximumAttempts {
          attempts += 1
          errors.append(error)
          queue.asyncAfter(deadline: .now() + retryInterval, execute: attempt)
        } else {
          promise.reject(NetworkError.tooManyFailedAttempts(attempts: attempts, errors: errors))
        }}
  }
  
  attempt()
  
  return promise
}
