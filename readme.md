# auto64-tunnel

auto64-tunnel is a script designed to automate the configuration of 6to4 tunnels, facilitating the transition from IPv4 to IPv6 by encapsulating IPv6 packets within IPv4 packets. This approach enables IPv6 connectivity over an existing IPv4 infrastructure.

## Features

- **Automated 6to4 Tunnel Configuration**: Simplifies the process of setting up 6to4 tunnels, reducing manual configuration efforts.
- **IPv6 Connectivity**: Provides IPv6 connectivity over IPv4 networks, aiding in the transition to IPv6.
- **Cross-Platform Compatibility**: Designed to work on various Unix-like operating systems.

## Prerequisites

- A Unix-like operating system (e.g., Linux, macOS).
- Administrative privileges to execute network configuration commands.
- An active IPv4 internet connection.

## Installation

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/Arash-Ariaye/auto64-tunnel.git
   ```

2. **Navigate to the Directory**:

   ```bash
   cd auto64-tunnel
   ```

3. **Make the Script Executable**:

   ```bash
   chmod +x 6to4Auto.sh
   ```

## Usage

1. **Run the Script with Administrative Privileges**:

   ```bash
   sudo ./6to4Auto.sh
   ```

   The script will:

   - Detect your public IPv4 address.
   - Configure the 6to4 tunnel using the detected IPv4 address.
   - Set up the appropriate routing to enable IPv6 connectivity.

2. **Verify IPv6 Connectivity**:

   After running the script, you can verify your IPv6 connectivity by pinging an IPv6 address:

   ```bash
   ping6 google.com
   ```

   If the ping is successful, your 6to4 tunnel is functioning correctly.

## Troubleshooting

- **Permission Denied**: Ensure you have executed the script with `sudo` or as a user with administrative privileges.
- **No IPv6 Connectivity**: Verify that your firewall settings allow 6to4 traffic and that your ISP supports 6to4 tunneling.
- **Script Errors**: Check the script's output for any error messages and ensure that your system's network configuration allows for 6to4 tunnel setup.

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a new branch:

   ```bash
   git checkout -b feature-branch
   ```

3. Make your changes.
4. Commit your changes:

   ```bash
   git commit -m "Description of changes"
   ```

5. Push to the branch:

   ```bash
   git push origin feature-branch
   ```

6. Open a Pull Request detailing your changes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
