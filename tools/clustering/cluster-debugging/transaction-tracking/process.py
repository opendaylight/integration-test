#!/usr/bin/env python

from datetime import datetime
import collections


class Transaction:
    def __init__(self, txnId, startTime, operations):
        self.txnId = txnId
        self.operations = operations
        self.startTime = datetime.strptime(startTime,
                                           '%Y-%m-%d,%H:%M:%S,%f')
        self.reachedTime = None
        self.completeTime = None

    def setReachedTime(self, reachedTime):
        self.reachedTime = datetime.strptime(reachedTime,
                                             '%Y-%m-%d,%H:%M:%S,%f')

    def setCompleteTime(self, completeTime):
        self.completeTime = datetime.strptime(completeTime,
                                              '%Y-%m-%d,%H:%M:%S,%f')

    def totalTime(self):
        return Transaction.diffInMicros(self.startTime, self.completeTime)

    def transferTime(self):
        return Transaction.diffInMicros(self.startTime, self.reachedTime)

    @staticmethod
    def diffInMicros(start, end):
        if end is not None and start is not None:
            delta = end - start
            seconds = delta.seconds
            microseconds = delta.microseconds
            return (seconds * 1000000 + microseconds) / 1000
        return -1

    def __str__(self):
        return "transactionId = " + self.txnId + ", " \
               + "operations = " + unicode(self.operations) + ", " \
               + "startTime = " + unicode(self.startTime) + ", " \
               + "reachedTime = " + unicode(self.reachedTime) + ", " \
               + "completeTime = " + unicode(self.completeTime) + ", " \
               + "transferTime = " + unicode(self.transferTime()) + ", " \
               + "totalTime = " + unicode(self.totalTime())

    def csv(self):
        return unicode(self.startTime) + "," \
            + self.txnId + "," \
            + unicode(self.operations) + "," \
            + unicode(self.transferTime()) + "," \
            + unicode(self.totalTime())

    @staticmethod
    def csv_header():
        return "Start Time,Transaction Id,Operations,Transfer Time," \
               "Complete Time"


def processFiles():
    txns = collections.OrderedDict()
    txnBegin = open("txnbegin.txt", "r")
    for line in txnBegin:
        arr = line.split(",")
        txns[arr[3]] = Transaction(arr[3],
                                   arr[0] + "," + arr[1] + "," + arr[2],
                                   int(arr[4]))

    txnReached = open("txnreached.txt", "r")
    for line in txnReached:
        arr = line.split(",")
        txnId = arr[3].strip()
        if txnId in txns:
            txn = txns[txnId]
            txn.setReachedTime(arr[0] + "," + arr[1] + "," + arr[2])

    txnComplete = open("txnend.txt", "r")
    for line in txnComplete:
        arr = line.split(",")
        txnId = arr[3].strip()
        if txnId in txns:
            txn = txns[txnId]
            txn.setCompleteTime(arr[0] + "," + arr[1] + "," + arr[2])

    return txns


def filterTransactionsByTimeToComplete(timeToComplete):
    txns = processFiles()
    totalTime = 0
    for txn in txns:
        if txns[txn].totalTime() > timeToComplete:
            print txns[txn]
            totalTime += txns[txn].totalTime()

    print "Total time for these transactions = " + unicode(totalTime)


def csv():
    txns = processFiles()
    print Transaction.csv_header()
    for txn in txns:
        print txns[txn].csv()
