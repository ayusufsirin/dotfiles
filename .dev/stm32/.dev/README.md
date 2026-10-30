# stm32-dev

Reproducible STM32 development environment for:

- Arch Linux host
- CLion installed on the host
- rootless Podman
- Distrobox for an interactive shell
- the same Podman image for CLion's Docker toolchain
- multiple STM32CubeMX / CubeCLT / CubeProgrammer versions

## Project information derived from Cube_v2.ioc

The supplied `.ioc` declares:

- MCU: `STM32F722RET6`
- family: `STM32F7`
- STM32CubeMX: `6.16.1`
- firmware package: `STM32Cube FW_F7 V1.17.0`
- compiler/linker: `GCC`
- generated target: `STM32CubeIDE`
- user-code preservation: enabled

The `.ioc` does **not** record the exact GNU Arm compiler version used by
the existing CubeIDE installation. Do not assume that Ubuntu's compiler is
bit-for-bit equivalent to the historical CubeIDE compiler.

## Design

There are two independent layers:

### 1. Base image

`localhost/stm32-dev:local`

Contains generic Linux dependencies:

- CMake
- Ninja
- GNU Arm Embedded GCC from Ubuntu
- GDB
- OpenOCD
- clangd / clang-tidy / clang-format
- cppcheck
- runtime libraries needed by typical ST Linux tools

Change the `Containerfile` only when these base dependencies change.

### 2. Persistent STM32 store

On the host:

```text
~/.local/share/stm32-dev/
├── tools/
│   ├── cubemx/
│   │   ├── 6.16.1/
│   │   └── ...
│   ├── cubeclt/
│   │   └── <version>/
│   └── cubeprogrammer/
│       └── <version>/
├── repository/
│   ├── STM32Cube_FW_F7_V1.17.0/
│   └── ...
├── profiles/
│   ├── Cube_v2.env
│   └── active.env -> Cube_v2.env
└── downloads/
```

Distrobox sees this directly because it shares your home directory.

For CLion, bind it to:

```text
/opt/stm32
```

using the Docker toolchain's **Container Settings**.

This means adding another CubeMX, CubeCLT, CubeProgrammer, or STM32 firmware
package does **not** require recreating Distrobox.

## First-time setup

From your STM32 project root after extracting `.dev`:

```bash
.dev/scripts/setup-store.sh
.dev/scripts/build-image.sh
.dev/scripts/verify-base.sh
.dev/scripts/create-distrobox.sh
.dev/scripts/verify-distrobox.sh
.dev/scripts/enable-podman-socket.sh
.dev/scripts/clion-settings.sh
```

Then enter the interactive environment:

```bash
distrobox enter stm32-dev
source /usr/local/share/stm32-dev/stm32-env.sh
stm32-tools
```

## Installing STM32CubeMX 6.16.1

Download the official Linux installer from ST yourself.

Keep the installer under:

```text
~/.local/share/stm32-dev/downloads/
```

Run it from inside the Distrobox so it sees an Ubuntu userspace and your
Wayland/X11 session:

```bash
distrobox enter stm32-dev
cd ~/.local/share/stm32-dev/downloads
chmod +x <the-downloaded-CubeMX-installer>
./<the-downloaded-CubeMX-installer>
```

When the installer asks for the installation directory, use:

```text
/home/<your-user>/.local/share/stm32-dev/tools/cubemx/6.16.1
```

Do not install it under `/usr` or `/opt` inside the mutable Distrobox.

After installation, from the project root run:

```bash
.dev/scripts/probe-st-install.sh
```

If the executable location is unusual, `probe-st-install.sh` will help locate it.

## STM32CubeF7 V1.17.0

Configure CubeMX's firmware repository to the persistent directory:

```text
~/.local/share/stm32-dev/repository
```

Then install/download `STM32Cube FW_F7 V1.17.0` from CubeMX.

The expected resulting directory is typically similar to:

```text
~/.local/share/stm32-dev/repository/STM32Cube_FW_F7_V1.17.0
```

Keep this repository outside the image. It is large and should survive image
and Distrobox recreation.

## Multiple versions

Install another CubeMX version into another directory:

```text
~/.local/share/stm32-dev/tools/cubemx/6.17.x
```

Likewise:

```text
~/.local/share/stm32-dev/tools/cubeclt/<version>
~/.local/share/stm32-dev/tools/cubeprogrammer/<version>
```

No image rebuild is required.

Profiles select versions. For the current project:

```bash
stm32-profile use Cube_v2
stm32-profile show
```

## CLion configuration

1. Enable the user Podman socket:

```bash
.dev/scripts/enable-podman-socket.sh
```

2. In CLion:

```text
Settings
→ Build, Execution, Deployment
→ Docker
```

Add a local Docker-compatible connection using the socket printed by:

```bash
.dev/scripts/clion-settings.sh
```

3. Create a toolchain:

```text
Settings
→ Build, Execution, Deployment
→ Toolchains
→ +
→ Docker
```

Image:

```text
localhost/stm32-dev:local
```

4. In the toolchain's **Container Settings**, add the volume binding printed by:

```bash
.dev/scripts/clion-settings.sh
```

It will look like:

```text
/home/<user>/.local/share/stm32-dev:/opt/stm32:rw
```

5. Add the toolchain environment file:

```text
/usr/local/share/stm32-dev/stm32-env.sh
```

6. Use this Docker toolchain in the project's CMake profile.

CLion mounts the project directory into the toolchain container and performs
CMake/build/run/debug actions inside the container.

## Existing Cube_v2 project

The current `.ioc` still says:

```text
ProjectManager.TargetToolchain=STM32CubeIDE
```

Do not overwrite the current working project immediately.

First commit or copy the complete existing project.

Then open `Cube_v2.ioc` using CubeMX 6.16.1 and generate a **CMake** project
into a temporary/branch directory. CubeMX supports `CMake` as a project
toolchain with GCC.

Compare the generated sources and build configuration with the current project
before switching the main project.

The current `.ioc` has `ProjectManager.KeepUserCode=true`, but version control
is still the safety net.

## What requires rebuilding?

### No rebuild / no Distrobox recreation

- add CubeMX 6.17 beside 6.16.1
- add another CubeCLT version
- add CubeProgrammer
- add STM32CubeH7/F7/G4 repository packages
- change the active project profile
- modify firmware source code

These live in the persistent store or project directory.

### Rebuild image, then recreate Distrobox

Only when changing base Linux dependencies in `Containerfile`, for example:

- install another apt package
- change Ubuntu version
- change the base OpenOCD/CMake/Clang packages

Commands:

```bash
.dev/scripts/build-image.sh
.dev/scripts/recreate-distrobox.sh
```

The persistent STM32 store and your projects are untouched.

## ST-LINK

Build first. Hardware debugging is deliberately the next layer.

Arch owns udev and physical USB permissions.

Once the firmware builds cleanly, expose ST-LINK to the CLion toolchain
container or run a GDB server on the host. Do not complicate the initial setup
with USB until compilation is proven.
