package lab2

/**
 *  产生式元信息存储
 */

public class ProductionInfo{
    public var indexId:Int64
    public var headName:String
    public var bodySize:Int64
    public init(indexId:Int64 ,headName:String ,bodySize:Int64) {
        this.indexId = indexId;
        this.headName = headName;
        this.bodySize =bodySize;
    }
}