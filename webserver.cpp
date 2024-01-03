  if (reqStruct.connectMethod_ == "POST"  && reqStruct.content_length_ > 0) {
    networkedLine=webSocket.ReceiveBytes();

    if (networkedLine.empty()){
      return reqStruct;
    }

    unsigned int pos_cr_lf = networkedLine.find_first_of("\x0a\x0d");
    
    if (pos_cr_lf == 0){
      return reqStruct;
    }

    std::string parsed_content = std::regex_replace(networkedLine, std::regex("\%5C"), "\\");

    std::cout << "Parsed: " << parsed_content << std::endl;

    reqStruct.content_ = parsed_content;
    reqStruct.content_ += "\n";
  }
  
  return reqStruct;
}

int webserver::respond(http_request reqStruct, Socket webSocket) {  
  std::stringstream str_str;
  time_t ltime;
  time(&ltime);
  tm* gmt= gmtime(&ltime);
  std::string response;

  static std::string const serverName = "IML's Web Server";

  char* asctime_remove_nl = asctime(gmt);
  asctime_remove_nl[24] = 0;

  response.append("HTTP/1.0 ");
  
  if (! reqStruct.auth_.empty() ) {
    webSocket.SendLine("401 Unauthorized");
    webSocket.SendBytes("WWW-Authenticate: Basic Realm=\"");
    webSocket.SendBytes(reqStruct.auth_);
    webSocket.SendLine("\"");
  }
  else {
    response.append(reqStruct.connectStatus_ + "");
  }

  if(reqStruct.stripped_content_.size() > 0) {
    reqStruct.sendBack_ += "Your stripped content: ";
    reqStruct.sendBack_ += reqStruct.stripped_content_;
    reqStruct.sendBack_ += "\n";
  }

  str_str << reqStruct.sendBack_.size();

  response.append("Connection: close\r\n");
  response.append(std::string("Date: ") + asctime_remove_nl + " GMT\r\n");
  response.append(std::string("Server: ") + serverName + "\r\n");
  response.append("Content-Type: text/html; charset=ISO-8859-1\r\n");
  response.append("Content-Length: " + str_str.str() + "\r\n");
  response.append("\r\n");
  response.append(reqStruct.sendBack_ + "\r\n");
  response.append("\r\n");

  webSocket.SendBytes(response);

  return 0;
}

webserver::webserver(unsigned int port_to_listen, req_function request) {
  SocketServer in(port_to_listen,5);

  req_function_ = request;

  while (1) {
    Socket * ptr_socket=in.Accept();
    std::thread t(Request,(void*)ptr_socket);
    t.join();
  }
}
