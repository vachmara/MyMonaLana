[![Actions Status](https://github.com/vachmara/MyMonaLana/workflows/main/badge.svg)](https://github.com/vachmara/MyMonaLana/actions)
[![code style: prettier](https://img.shields.io/badge/code_style-prettier-ff69b4.svg)](https://github.com/prettier/prettier)
[![license](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# My Mona Lana contract

## To Do 

- [ ] Define cost of each NFTs at each stages (pre-sale, public sale)
- [ ] Define repartition of the tokenemics (wallets redistribution, payment splitter)
- [ ] Define if VRF function need to take in account the number of token hold by each holder (If I own 5 Monas, do I have more chance to be airdrop an random trait than a 1 Mona holder ?) 
- [ ] Store informations efficiently about 2-3 layers potentially for each holder 
- [ ] Access efficiently to these stored datas
- [ ] Smart contract have right to mint ? (multi sig wallet cannot be able to mint but it protect against Max mint smart contract attack)
- [ ] Free mint for mona console holder 
- [ ] Whitelist people
- [ ] VRF function to choose randomly airdrop object
- [ ] Test 

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

**My Mona Lana** contract is released under the [Apache-2.0](LICENSE).