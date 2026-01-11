package com.runwar

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class RunWarApplication

fun main(args: Array<String>) {
    runApplication<RunWarApplication>(*args)
}
