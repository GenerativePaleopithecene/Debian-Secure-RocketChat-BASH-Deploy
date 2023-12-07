# Rocket.Chat Secure Server Setup Script

## Overview

This script automates the setup of a Rocket.Chat server on a Debian minimal server. It includes the installation of MongoDB, Node.js, and Nginx, as well as configuring security measures like Fail2Ban, Auditd, SSH hardening, and a self-signed SSL certificate.

## Features

- Automated installation of MongoDB and Node.js
- Configuration of MongoDB security
- Creation and setup of Rocket.Chat server
- Configuration of Nginx as a reverse proxy for Rocket.Chat
- Security enhancements including Fail2Ban, Auditd, and SSH hardening
- Creation of a self-signed SSL certificate for HTTPS
- Set up of UFW with correct ports

## Prerequisites

- A fresh Debian minimal server installation
- Root or sudo privileges

**Note:** This script is optimized for Debian minimal server environments. Debian's stability and minimal footprint make it an ideal choice for server setups like this one. While the script might work on other distributions like Ubuntu, it's specifically tested and maintained for Debian.

Scan the script and change what you need before deployment. As-is it's pretty strong. In the future, rocketchat download locations may change.

## Installation

1. Clone this repository or download the script:

  ```bash
   git clone https://github.com/GenerativePaleopithecene/Debian-Secure-RocketChat-BASH-Deploy
   ```

2. Make the script executable:

   ```bash
   chmod +x setuprocketchat.sh
   ```

3. Run the script as root

   ```bash
   sudo ./setuprocketchat.sh
   ```


## Usage

After running the script, your Rocket.Chat server should be up and running. You can access it via your web browser at `https://your-domain.com:3000/` or through the configured Nginx reverse proxy.

## Customizing the Script

- You may need to modify certain parameters in the script such as domain names, ports, or MongoDB user credentials to match your requirements.
- Ensure to replace `your-domain.com` with your actual domain name.

## Security Notes

- The script includes a self-signed SSL certificate. Why? Because as you will see in late 2023 and beyond you will no longer be able to trust CAs.
- MongoDB and SSH configurations are set for enhanced security. Adjust as necessary for your environment.

## Contributing

Contributions to improve this script are welcome. Please follow the standard process for submitting pull requests.

## License

This project is licensed under the GPL3 License - see the [LICENSE.md](LICENSE.md) file for details.


