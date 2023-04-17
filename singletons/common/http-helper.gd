extends Node

func CreateHttpRequest():
	var httpRequest = HTTPRequest.new()
	add_child(httpRequest)
	return httpRequest
