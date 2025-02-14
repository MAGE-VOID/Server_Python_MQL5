# MQL5 Socket Client - Python Server

This repository demonstrates TCP socket communication between an MQL5 Expert Advisor (EA) and a Python server, enabling data exchange between MetaTrader 5 and external applications. The MQL5 EA sends closing price data to a Python server, which responds with a confirmation.

## Files

*   **`ServerLocal.py`**: Python TCP socket server. Listens for connections and sends a test response.
*   **`ExpertServer.mql5`**: MQL5 Expert Advisor client. Sends closing prices and displays server responses.

## Functionality

*   **Python Server (`ServerLocal.py`):** Simple TCP server echoing a test message back to clients.
*   **MQL5 Expert Advisor (`ExpertServer.mql5`):**

    *   **Security:** **Verifies that the server address is whitelisted in MetaTrader 5 "Allow WebRequest for listed URLs" settings.**  The EA will not connect if the address is not whitelisted.
    *   **TCP Socket Client:** Connects to the Python server.
    *   **Data Transmission:** Periodically sends current symbol closing prices.
    *   **Response Handling:** Receives and displays server responses in the Experts tab.
    *   **Robust Reconnection:**  Automatically reconnects if the server restarts or connection is lost, both on startup and during runtime.

## Setup Instructions

### Python Server

1.  **Install Python 3.x.**
2.  **Save `ServerLocal.py`.**
3.  **Run:** `python ServerLocal.py` in a terminal.

### MQL5 Client

1.  **Save `ExpertServer.mql5`** to `MQL5\Experts`.
2.  **Whitelist Server Address:**  **Important:**
    *   In MetaTrader 5, go to **Tools > Options > Expert Advisors**.
    *   Check **"Allow WebRequest for listed URLs"**.
    *   Add **`localhost`** (or your server address) to the list and click **OK**.

## How to Run

1.  **Start Python Server:** Execute `ServerLocal.py`.
2.  **Start MQL5 EA:** Drag `ExpertServer.mql5` to a chart in MT5 and click "OK".
3.  **Observe Output:**
    *   **Python Server Terminal:** Shows "Received data: ..." with closing prices.
    *   **MT5 "Experts" Tab:** Displays connection status and server responses ("Server response: Test string...").