package lab2
import std.collection.*

/**
 *  继承Cell类，处理LR分析表的GOTO转移
 */

public class GotoCell {
    // 纵坐标：状态序号
    public var stateId:Int64
    // 横坐标：非终结符
    public var nonTerminalStmbolName:String
    // 下一状态
    public var nextStateId:Int64
    public init(stateId:Int64 ,nonTerminalStmbolName:String ,nextStateId:Int64) {
        this.stateId = stateId;
        this.nonTerminalStmbolName = nonTerminalStmbolName;
        this.nextStateId = nextStateId;
    }
}