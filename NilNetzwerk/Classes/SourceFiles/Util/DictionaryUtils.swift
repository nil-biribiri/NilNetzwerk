import Foundation

extension Dictionary where Key == String, Value == AnyObject {
  func prettyPrint() -> String{
    var string: String = ""
    if let data = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted){
      if let nstr = NSString(data: data, encoding: String.Encoding.utf8.rawValue){
        string = nstr as String
      }
    }
    return string
  }
}

extension Encodable {
  var dictionary: [String: Any]? {
    guard let data = try? JSONEncoder().encode(self) else { return nil }
    return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
  }
}
