//+------------------------------------------------------------------+
//|                                                 SocketClient.mq5 |
//|                        Copyright 2025, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.04"

int clientSocket = INVALID_HANDLE;

string server = "localhost";
int serverPort = 9090;
bool isConnected = false;

input int RetryDelayOnInit_ms = 2000; // Delay between retries in milliseconds during initial connection

//+------------------------------------------------------------------+
//| Expert initialization handler                                    |
//+------------------------------------------------------------------+
int OnInit()
{
  EventSetTimer(1);

  if (!WaitForInitialConnection())
  {
    Print("Expert Advisor stopped before connection was established.");
    return INIT_FAILED;
  }

  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Waits indefinitely for initial connection during OnInit          |
//+------------------------------------------------------------------+
bool WaitForInitialConnection()
{
  while (!IsStopped())
  {
    Print("Attempting initial connection to server...");
    if (AttemptConnection())
    {
      Print("Initial connection established successfully.");
      return true;
    }
    else
    {
      Print("Initial connection attempt failed. Retrying in ", RetryDelayOnInit_ms / 1000.0, " seconds...");
      Sleep(RetryDelayOnInit_ms);
    }
  }
  return false;
}

//+------------------------------------------------------------------+
//| Attempts to establish a connection to the server                 |
//+------------------------------------------------------------------+
bool AttemptConnection()
{
  if (clientSocket != INVALID_HANDLE)
  {
    SocketClose(clientSocket);
    clientSocket = INVALID_HANDLE;
    isConnected = false;
  }

  clientSocket = SocketCreate();
  if (clientSocket == INVALID_HANDLE)
  {
    Print("Socket creation failed. Error: ", GetLastError());
    return false;
  }

  if (!SocketConnect(clientSocket, server, serverPort, 1000))
  {
    Print("Connection to ", server, ":", serverPort, " failed. Error: ", GetLastError());
    SocketClose(clientSocket);
    clientSocket = INVALID_HANDLE;
    isConnected = false;
    return false;
  }

  isConnected = true;
  Print("Connected to server: ", server, ":", serverPort);
  return true;
}

//+------------------------------------------------------------------+
//| Timer event handler                                              |
//+------------------------------------------------------------------+
void OnTimer()
{
  if (!isConnected)
  {
    if (!AttemptConnection())
    {
      Print("Attempting reconnection from timer...");
      return;
    }
  }

  double closingPrices[];
  int copied = CopyClose(_Symbol, PERIOD_CURRENT, 0, 1, closingPrices);

  if (copied <= 0)
  {
    Print("Failed to copy closing prices. Error: ", GetLastError());
    return;
  }

  string payload = "";
  for (int i = 0; i < ArraySize(closingPrices); i++)
    payload += (string)closingPrices[i] + " ";

  SendReceiveData(payload);
}

//+------------------------------------------------------------------+
//| Handle data transmission and reception                           |
//+------------------------------------------------------------------+
void SendReceiveData(string payload)
{
  if (clientSocket == INVALID_HANDLE)
  {
    Print("Socket is invalid, attempting reconnection before sending data.");
    isConnected = false;
    return;
  }

  bool success = SocketSend(clientSocket, payload);
  if (!success)
  {
    Print("Socket send failed, awaiting server response... (possible disconnection)");
    isConnected = false;
    return;
  }

  string response = SocketReceive(clientSocket, 10);

  if (response == "")
  {
    Print("Awaiting server response...");
    isConnected = false;
  }
  else
  {
    Print("Server response: ", response);
    isConnected = true;
  }
}

//+------------------------------------------------------------------+
//| Safe socket transmission implementation                          |
//+------------------------------------------------------------------+
bool SocketSend(int socket, string request)
{
  char dataBuffer[];
  int convertedSize = StringToCharArray(request, dataBuffer) - 1;

  if (convertedSize < 0)
    return false;

  int sentBytes = SocketSend(socket, dataBuffer, convertedSize);
  return (sentBytes == convertedSize);
}

//+------------------------------------------------------------------+
//| Robust socket reception with timeout handling                   |
//+------------------------------------------------------------------+
string SocketReceive(int socket, int timeoutMs)
{
  uchar responseBuffer[];
  string fullResponse = "";
  uint bytesAvailable;
  uint timeoutThreshold = GetTickCount() + timeoutMs;

  do
  {
    bytesAvailable = SocketIsReadable(socket);
    if (bytesAvailable > 0)
    {
      int bytesRead = SocketRead(socket, responseBuffer, bytesAvailable, timeoutMs);
      if (bytesRead > 0)
        fullResponse += CharArrayToString(responseBuffer, 0, bytesRead);
    }
    else if (!isConnected)
    {
      Sleep(1);
    }
  } while ((GetTickCount() < timeoutThreshold) && !IsStopped());

  return fullResponse;
}

//+------------------------------------------------------------------+
//| Expert deinitialization handler                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  SocketClose(clientSocket);
  EventKillTimer();
  isConnected = false;
  Print("Socket closed and timer stopped.");
}
//+------------------------------------------------------------------+