import socket


class SocketServer:
    """TCP Socket server implementation for handling client connections and data exchange."""

    def __init__(self, address="", port=9090):
        """
        Initialize the server socket with specified address and port.

        Args:
            address (str): Host address to bind (default: any available interface)
            port (int): Port number to listen on (default: 9090)
        """
        self.host = address
        self.port = port
        self.serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.serversocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.serversocket.bind((self.host, self.port))
        self.serversocket.listen(5)
        print(f"Server running on {self.host}:{self.port}...")

    def start(self):
        """Start listening for incoming connections and handle client communication."""
        try:
            while True:
                client_socket, client_address = self.serversocket.accept()
                try:
                    self._handle_client(client_socket)
                except Exception as e:
                    print(f"Client handling error: {str(e)}")
                finally:
                    client_socket.close()
        except KeyboardInterrupt:
            print("\nServer shutdown requested")
        finally:
            self.serversocket.close()

    def _handle_client(self, client_socket):
        """Handle communication with an individual client connection."""
        while True:
            data = self._receive_complete_message(client_socket)
            if not data:
                break

            print(f"Received data: {data.decode()}")
            response = "Test string send from ServerLocal.py"
            client_socket.send(response.encode())

    def _receive_complete_message(self, client_socket):
        """
        Receive complete message from socket using length-agnostic approach.

        Returns:
            bytes: Complete message received from client
        """
        buffer = bytearray()
        while True:
            try:
                chunk = client_socket.recv(1024)
                if not chunk:
                    break
                buffer.extend(chunk)
                if len(chunk) < 1024:
                    break
            except (socket.timeout, BlockingIOError):
                break
            except Exception as e:
                print(f"Data reception error: {str(e)}")
                break
        return bytes(buffer)


if __name__ == "__main__":
    server = SocketServer(address="localhost", port=9090)
    server.start()
