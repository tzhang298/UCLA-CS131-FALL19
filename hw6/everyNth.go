package main

import (
  "fmt"
  "container/list"
)

func everyNth(l *list.List, N int) *list.List {
	result := list.New()
	i := 0
	for temp := l.Front(); temp != nil; temp = temp.Next() {
        	if (i+1)%N==0 {
    		  	result.PushBack(temp.Value)
    		}
        	i++
  	}
	return result
}
func main() {
	//initialize variables
	length_of_list := 1000
	N := 109
	//create list of 1000 nonnegaive integers
	l := list.New()
  	for i := 0; i < length_of_list; i++ {
    		l.PushBack(i)
  	}
	//test the function
  	answer := everyNth(l,N)
  	for temp := answer.Front(); temp != nil; temp = temp.Next() {
        	fmt.Println(temp.Value)
  	}
}
