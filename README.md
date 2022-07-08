[![Actions Status](https://github.com/vachmara/MyMonaLana/workflows/main/badge.svg)](https://github.com/vachmara/MyMonaLana/actions)
[![code style: prettier](https://img.shields.io/badge/code_style-prettier-ff69b4.svg)](https://github.com/prettier/prettier)
[![license](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# Sparkso ICO contract

## Overview

TO DO

### 📦 Installation

```console
$ yarn
```
or 

```console
$ npm i
```

### ⛏️ Compile

```console
$ yarn compile
```
or

```console
$ npm run compile
```

This task will compile all smart contracts in the `contracts` directory.
ABI files will be automatically exported in `build/abi` directory.

### 📚 Documentation

Documentation is auto-generated after each build in [`docs`](https://vachmara.github.io/MyMonaLana/docs) directory.

The generated output is a static website containing smart contract documentation.

### 🌡️ Testing

```console
$ yarn test
```
or

```console
$ npm run test
```

### 📊 Code coverage

```console
$ yarn coverage
```
or

```console
$ npm run coverage
```

The report will be printed in the console and a static website containing full report will be generated in [`coverage`](https://vachmara.github.io/sparkso-token/coverage) directory.

### ✨ Code style

```console
$ yarn prettier
```
or

```console
$ npm run prettier
```

### 🐱‍💻 Verify & Publish contract source code

```console
$ npx hardhat  verify --network mainnet $CONTRACT_ADDRESS $CONSTRUCTOR_ARGUMENTS
```

## 📄 License

**Sparkso ICO contracts** is released under the [Apache-2.0](LICENSE).