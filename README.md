# Container Scanning 1 - Heuristic Auto-Linking Demo

This repository demonstrates **Arnica's heuristic container-to-source auto-linking** for Python-based containers.

## What This Tests???

When a container image is pushed to a registry, Arnica can automatically link it back to the source Dockerfile in your repository using two methods:

1. **Annotation-based linking** (deterministic, high confidence) - uses OCI labels embedded in Dockerfiles
2. **Heuristic linking** (probabilistic, lower confidence) - analyzes container build history

**This repository tests method #2: Heuristic linking without OCI annotations.**

### How Heuristic Linking Works

1. When you build a Docker image, the build history (all commands executed) is stored in the image metadata
2. Arnica scans your container registry and extracts this build history
3. Arnica compares the history lines against Dockerfile contents in your source repositories
4. If enough lines match uniquely, Arnica links the container to that Dockerfile
5. Assignment type: `lines` (confidence score: 50, but we should be removing confidence soon)

This approach works without modifying your Dockerfiles, but has lower confidence than annotation-based linking.

---

## Files in This Repository

```
awesome-lines.Dockerfile  - Sample Dockerfile with intentional vulnerabilities
requirements.txt         - Python dependencies (some with known CVEs)
README.md               - This file
```

**Note:** The Dockerfile intentionally includes:
- `httpx==0.15.3` installed via RUN command (has known CVEs)
- Dependencies in `requirements.txt` that may have vulnerabilities
- Commands that create unique build history for matching

---

## Setup Instructions

### Prerequisites

- GitHub account with a repository where you'll test this
- Docker installed locally
- GitHub Container Registry (GHCR) access configured
- Arnica account with container scanning enabled

### Step 1: Copy Files to Your Test Repository

```bash
# Set your destination repository path
DEST_REPO="/path/to/your/test/repo"

# Copy the test files
cp awesome-lines.Dockerfile "$DEST_REPO/"
cp requirements.txt "$DEST_REPO/"

echo "✓ Files copied to $DEST_REPO"
```

### Step 2: Commit and Push to Main Branch

```bash
cd "$DEST_REPO"
git add awesome-lines.Dockerfile requirements.txt
git commit -m "Add heuristic linking test Dockerfile"
git push origin main
```

### Step 3: Build and Push Docker Image

```bash
cd "$DEST_REPO"

# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# Build the image
docker build -f awesome-lines.Dockerfile -t ghcr.io/YOUR_ORG/container-scanning-1:latest .

# Push the image
docker push ghcr.io/YOUR_ORG/container-scanning-1:latest
```

**Important:** Replace `YOUR_ORG` and `YOUR_GITHUB_USERNAME` with your actual values.

### Step 4: Integrate Repository with Arnica

1. Log into Arnica
2. Go to **Settings** → **Integrations** → **GitHub**
3. Add your test repository (if not already added)
4. Wait 1-2 minutes for initial sync

### Step 5: Integrate Container Registry with Arnica

1. In Arnica: **Settings** → **Integrations** → **Container Registries**
2. Add GitHub Container Registry (GHCR) integration
3. Follow the setup guide: [Container Integrations Documentation](https://docs.arnica.io/arnica-documentation/getting-started/container-integrations/ghcr)
4. Ensure container scanning correlation is enabled for your tenant
5. Wait for Arnica to scan your registry (~2-5 minutes)

### Step 6: Verify No OCI Annotation Policy

**Critical:** To test heuristic linking, you must ensure Dockerfiles are NOT tagged with OCI annotations.

1. In Arnica: **Policies** → Find any policy that includes "Tag Dockerfiles" or "Label all Dockerfiles"
2. **Disable** or **exclude this repository** from that policy
3. This forces Arnica to use heuristic matching instead of annotation-based matching

### Step 7: Verify Auto-Linking

1. Go to **Inventory** → **Container Images**
2. Find your image: `ghcr.io/YOUR_ORG/container-scanning-1`
3. Click on the image to view details
4. Check the **"Source Code Location"** section:
   - **Expected:** Repository and Dockerfile path should be automatically detected
   - **Assignment Type:** Should show `lines` (heuristic matching)
   - **Confidence:** 50 (lower confidence due to probabilistic matching)
5. Click **"View in Repository"** to navigate to the linked Dockerfile

### Step 8: View Vulnerabilities

1. In the container image details, click the **Vulnerabilities** tab
2. You should see CVEs detected in:
   - `httpx==0.15.3`
   - Dependencies from `requirements.txt`
   - Base image `python:3.9.11`
3. Click **"View findings linked to source code repository"** to see CVEs correlated to your source repo

**Note:** Vulnerability correlation to source code only happens if:
- The container is successfully linked to a repository (check "Source Code Location" is populated)
- Container scanning correlation is enabled for your tenant
- The repository has been scanned by Arnica

---

## How to Verify This is Heuristic Linking

1. In Arnica, navigate to the container image details
2. Look for **"Assignment Type: lines"** (not "labels")
3. Open the Dockerfile in your repository - it should have NO OCI annotation block like:
   ```dockerfile
   # You should NOT see this block (that would be annotation-based linking)
   # ================ ARNICA SECURITY ANNOTATION BLOCK START ================
   LABEL org.opencontainers.image.source="..."
   LABEL org.opencontainers.image.path="..."
   # ================ ARNICA SECURITY ANNOTATION BLOCK END ================
   ```

---

## Troubleshooting

### Container Not Linked to Repository

**Possible causes:**
- Build history is too generic (not enough unique commands)
- Multiple Dockerfiles have similar content (ambiguous match)
- Repository not yet scanned by Arnica

**Solutions:**
- Add unique RUN commands to your Dockerfile (e.g., `RUN echo "unique-identifier-12345"`)
- Wait 5-10 minutes for Arnica to process the container scan
- Check Arnica logs in **Jobs** → **Recent Tasks** for container scanning jobs

### Container Shows "labels" Assignment Type Instead of "lines"

**Cause:** A policy automatically tagged your Dockerfile with OCI annotations.

**Solution:**
- Check your repository for a recent commit that added LABEL directives to the Dockerfile  
- Disable or exclude this repository from any "Tag Dockerfiles" or "Label all Dockerfiles" policy
- Remove the LABEL annotation block from your Dockerfile and rebuild/push the image

### No Vulnerabilities Showing

**Cause:** Container scan may still be in progress.

**Solution:**
- Wait 5-10 minutes after pushing the image
- Check **Jobs** → **Container Scans** for scan status
- Verify your container registry integration is working

---


## Next Steps

After testing heuristic linking, try **container-scanning-2** to see annotation-based linking in action.

## Links to docs

- [Container Images Documentation](https://docs.arnica.io/arnica-documentation/inventory/container-images)
- [Adding OCI Tags to Docker Images](https://docs.arnica.io/arnica-documentation/developers/adding-oci-tags-to-docker-images)
- [Container Integrations](https://docs.arnica.io/arnica-documentation/getting-started/container-integrations/ghcr)
