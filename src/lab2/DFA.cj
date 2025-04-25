package lab2
import std.collection.*

/**
 *  定义语法分析DFA结构
 *  包含状态转移表和初始状态
 */

public class DFA{
    public var startupItemSet:ItemSet
    public var pEdgeTable:ArrayList<TransitionEdge>
    public init(startupItemSet:ItemSet ,pEdgeTable:ArrayList<TransitionEdge>) {
        this.startupItemSet = startupItemSet;
        this.pEdgeTable = pEdgeTable;
    }
}