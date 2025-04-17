package demo

import std.collection.*

// CharSet.cj
// 仓颉编程语言实现的字符集库
// 每个字符集由若干段构成，每段记录一段连续字符范围

// 定义字符集段类
class CharSet {
    // 字符集 id
    var indexId : UInt32
    // 段 id
    var segmentId : UInt32
    // 段起始字符
    var fromChar : Rune
    // 段结束字符
    var toChar : Rune

    init(id: UInt32, segId: UInt32, from: Rune, to: Rune) {
        this.indexId = id
        this.segmentId = segId
        this.fromChar = from
        this.toChar = to
    }
}

// 全局字符集表，用于存储所有字符集的各个段
var charSetTable: ArrayList<CharSet> = ArrayList<CharSet>()
// 字符集 id 的计数器
var charSetCounter: UInt32 = 1

// 创建字符范围 [fromChar, toChar]，将该范围作为一个段存入全局表，返回新的字符集 id
func range(fromChar: Rune, toChar: Rune): UInt32 {
    charSetTable.append(CharSet(charSetCounter, 1, fromChar, toChar))
    let result = charSetCounter
    charSetCounter = charSetCounter + 1
    return result
}

// 将两个字符分别作为单独段加入新的字符集，返回新的字符集 id
func unionChars(c1: Rune, c2: Rune): UInt32 {
    let newId = charSetCounter
    charSetCounter = charSetCounter + 1
    charSetTable.append(CharSet(newId, 1, c1, c1))
    charSetTable.append(CharSet(newId, 2, c2, c2))
    return newId
}

// 将字符加入已有字符集中，复制原字符集所有段，并新增一个单字符段，返回新的字符集 id
func unionCharSetWithChar(charSetId: UInt32, c: Rune): UInt32 {
    let newId = charSetCounter
    charSetCounter = charSetCounter + 1
    var newSegmentId: UInt32 = 1
    for (i in 0..charSetCounter-1) {
        if (charSetTable[Int64(i)].indexId == charSetId) {
            charSetTable.append(CharSet(newId, newSegmentId, charSetTable[Int64(i)].fromChar, charSetTable[Int64(i)].toChar))
            newSegmentId = newSegmentId + 1
        }
    }
    // 添加新的字符作为一个段
    charSetTable.append(CharSet(newId, newSegmentId, c, c))
    return newId
}

// 将两个字符集的所有段合并到新的字符集中，返回新的字符集 id
func unionCharSets(charSetId1: UInt32, charSetId2: UInt32): UInt32 {
    let newId = charSetCounter
    charSetCounter = charSetCounter + 1
    var newSegmentId: UInt32 = 1
    for (i in 0..charSetCounter-1) {
        if (charSetTable[Int64(i)].indexId == charSetId1 || charSetTable[Int64(i)].indexId == charSetId2) {
            charSetTable.append(CharSet(newId, newSegmentId, charSetTable[Int64(i)].fromChar, charSetTable[Int64(i)].toChar))
            newSegmentId = newSegmentId + 1
        }
    }
    return newId
}

// 从指定字符集中去除字符 c，若 c 在某段中则拆分该段为最多两个新的段，返回新的字符集 id
func difference(charSetId: UInt32, c: Rune): UInt32 {
    let newId = charSetCounter
    charSetCounter = charSetCounter + 1
    var newSegmentId: UInt32 = 1
    for (i in 0..charSetCounter-1) {
        if (charSetTable[Int64(i)].indexId == charSetId) {
            if (c < charSetTable[Int64(i)].fromChar || c > charSetTable[Int64(i)].toChar) {
                // 待删除字符不在此段，直接复制
                charSetTable.append(CharSet(newId, newSegmentId, charSetTable[Int64(i)].fromChar, charSetTable[Int64(i)].toChar))
                newSegmentId = newSegmentId + 1
            } else {
                // 如果待删除字符在段中，则拆分为最多两个段
                if (charSetTable[Int64(i)].fromChar < c) {
                    // 左侧部分：[seg.fromChar, c-1]
                    charSetTable.append(CharSet(newId, newSegmentId, charSetTable[Int64(i)].fromChar, Rune(UInt32(c) - 1)))
                    newSegmentId = newSegmentId + 1
                }
                if (charSetTable[Int64(i)].toChar > c) {
                    // 右侧部分：[c+1, seg.toChar]
                    charSetTable.append(CharSet(newId, newSegmentId, Rune(UInt32(c) + 1), charSetTable[Int64(i)].toChar))
                    newSegmentId = newSegmentId + 1
                }
            }
        }
    }
    return newId
}

// 打印全局字符集表
func printTable() {
    // 打印标题
    println("IndexId    SegmentId    FromChar    ToChar")
    println("--------------------------------------------")
    for (seg in charSetTable) {
        // 这里简单用制表符分隔各列

        println("${seg.indexId}  ${seg.segmentId}  ${seg.fromChar}  ${seg.toChar}")
    }
}

// 打印指定字符集
func printCharSet(charSetId: UInt32) {
    println("CharSet ID: ${charSetId}")
    for (seg in charSetTable) {
        if (seg.indexId == charSetId) {
            println("  Segment ${seg.segmentId}: ${seg.fromChar} to ${seg.toChar}")
        }
    }
}