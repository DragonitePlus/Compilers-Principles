package lab2
import std.collection.*

/**
 *  基础单元格类，存储通用单元格结构
 */

public class Cell {
    public var nonTerminalSymbol:NonTerminalSymbol
    public var terminalSymbol:TerminalSymbol
    public var production:Production
    public init(nonTerminalSymbol:NonTerminalSymbol , terminalSymbol:TerminalSymbol ,production:Production) {
        this.nonTerminalSymbol = nonTerminalSymbol;
        this.terminalSymbol = terminalSymbol;
        this.production = production;
    }

}