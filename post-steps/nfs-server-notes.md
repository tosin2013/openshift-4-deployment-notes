# How to Configure an NFS Server on CentOS 9

Network File System (NFS) is a distributed file system protocol that allows you to share directories and files with others over a network. Configuring an NFS server on CentOS 9 is straightforward and highly beneficial for creating a centralized file storage system that can be accessed by multiple clients. This guide will walk you through the process of setting up an NFS server on CentOS 9.

## Table of Contents

1. [Introduction to NFS](#introduction-to-nfs)
2. [Prerequisites](#prerequisites)
3. [Step-by-Step Guide to Configuring NFS Server](#step-by-step-guide-to-configuring-nfs-server)
    - [Step 1: Install NFS Utilities](#step-1-install-nfs-utilities)
    - [Step 2: Create and Configure NFS Export Directory](#step-2-create-and-configure-nfs-export-directory)
    - [Step 3: Configure NFS Export File](#step-3-configure-nfs-export-file)
    - [Step 4: Start and Enable NFS Service](#step-4-start-and-enable-nfs-service)
    - [Step 5: Configure Firewall](#step-5-configure-firewall)
4. [Setting Up NFS Client](#setting-up-nfs-client)
5. [Testing NFS Server](#testing-nfs-server)
6. [Conclusion](#conclusion)

## Introduction to NFS

NFS, or Network File System, allows a system to share directories and files with others over a network. The NFS protocol enables systems to access files over a network as easily as if they were on local storage. This is especially useful in environments where multiple users need to access shared data.

## Prerequisites

Before you begin, you need:
- A CentOS 9 server with root or sudo access.
- Basic understanding of Linux command-line operations.

## Step-by-Step Guide to Configuring NFS Server

### Step 1: Install NFS Utilities

First, we need to install the NFS utilities on the server. This can be done using the DNF package manager.

```bash
sudo dnf install nfs-utils -y
```

### Step 2: Create and Configure NFS Export Directory

Create a directory that you wish to share with clients. For example, we will create a directory named `nfs_shared` in `/srv`.

```bash
sudo mkdir -p /srv/nfs_shared
```

Set the appropriate permissions for the directory.

```bash
sudo chown nfsnobody:nfsnobody /srv/nfs_shared
sudo chmod 755 /srv/nfs_shared
```

### Step 3: Configure NFS Export File

Edit the `/etc/exports` file to specify the directories to share and their permissions.

```bash
sudo nano /etc/exports
```

Add the following line to share the directory with clients. Replace `client_IP` with the actual IP address of the client that will access the NFS share.

```plaintext
/srv/nfs_shared client_IP(rw,sync,no_subtree_check)
```

### Step 4: Start and Enable NFS Service

Start and enable the NFS service to ensure it starts at boot.

```bash
sudo systemctl enable --now nfs-server
```

### Step 5: Configure Firewall

Allow NFS traffic through the firewall.

```bash
sudo firewall-cmd --permanent --add-service=nfs
sudo firewall-cmd --reload
```

## Setting Up NFS Client

To access the NFS share from a client machine, install the NFS utilities and mount the shared directory.

```bash
sudo dnf install nfs-utils -y
sudo mount -t nfs server_IP:/srv/nfs_shared /mnt
```

Replace `server_IP` with the IP address of your NFS server.

## Testing NFS Server

To confirm that the NFS server is working correctly, create a test file on the server and verify that it appears on the client machine.

```bash
sudo touch /srv/nfs_shared/testfile
```

On the client machine, check if `testfile` is present in the `/mnt` directory.

```bash
ls /mnt
```

## Conclusion

Configuring an NFS server on CentOS 9 can significantly streamline file sharing across your network. By following this guide, you should have a fully functional NFS server up and running, allowing multiple clients to access centralized data seamlessly.

For more advanced configurations and troubleshooting tips, consult the official CentOS documentation or additional resources. Happy networking!

Feel free to leave a comment below if you have any questions or run into any issues.