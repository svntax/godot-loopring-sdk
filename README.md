# godot-loopring-sdk
A simple SDK to integrate Loopring into Godot web games.

### Note: This project is still a work-in-progress.

To-Do's:
- `resolve_ens` is untested
- Mobile is untested
- WalletConnect QR code login/signing

## Features
- User login/logout through a Loopring compatible wallet.
- Fetch the user's NFT balance.

## API Calls
These API calls are currently supported. See `TestMainScene.tscn` for an example scene of how to use them. More can be added to the `Loopring.gd` script.

| Function | Use |
| ------ | ------ |
| get_api_key | Gets the user's L2 API Key |
| get_account_object | Gets the user's account information |
| get_token_balance | Gets the user's NFT data |
| resolve_ens | Gets Loopring ENS |
| get_metadata | Gets metadata from IPFS |

## Getting Started
Download the C# Mono version of Godot 3.5.2. Then either clone this repository and import the project, or just copy the `addons/godot-loopring-sdk` directory into your own project's `addons` directory and enable the SDK from Godot's plugins menu.

If you're copying the SDK over, make sure that your `.csproj` file has the following elements in `<PropertyGroup>` and `<ItemGroup>`:
```xml
<PropertyGroup>
  <TargetFramework>net472</TargetFramework>
  <LangVersion>latest</LangVersion>
  <AllowUnsafeBlocks>true</AllowUnsafeBlocks>
</PropertyGroup>
```
```xml
<ItemGroup>
  <PackageReference Include="PoseidonSharp" Version="1.0.0" />
</ItemGroup>
``` 

### Wallet Login/Logout
See `TestLogin.tscn` for an example login scene.

To connect to a user's wallet, add a Node with the `WalletConnector.gd` script attached to it. Then you can call WalletConnector's `connect_to_web3_wallet()` function and `LoopringGlobals.set_wallet_type()` with the wallet type the user picks. In the example login scene, there are 3 buttons for Metamask, GameStop, and WalletConnect. The wallet type needs to be passed into the above functions for the right connection process to happen.

When a wallet connection succeeds or fails, `WalletConnector.gd` emits a `wallet_connected` signal with the wallet string as its parameter. An empty string means the connection failed somehow, in which case you'll want to clear all global wallet data with `LoopringGlobals.clear_wallet()`. If the connection was successful, you can save the user's wallet and wallet type by writing to a ConfigFile, which lets you keep the user logged in. In the example login scene, we check if there's a user config file saved on ready, and we skip the login screen if a wallet is found.

You can log out the user by calling `Loopring.logout()`, which deletes all data from the config file located at `LoopringGlobals.USER_DATA_SAVE_PATH` and from the `LoopringGlobals` singleton itself.

### Using the Loopring API
See `TestMainScene.tscn` for an example on how to use the Loopring API. Note that this scene also has its own node with `WalletConnector.gd` attached to it.

To query for the user's NFTs, we need a L2 API key. We can get the user's API key by querying for some data that eventually gets converted and passed into `Loopring.get_api_key()`. This entire process can be seen `MainSceneManager.gd`'s functions `get_account()`, `sign_message_function()`, and `get_api_key()`.

#### API key retrieval process (How it works)
First, we get the user's account data with `Loopring.get_account_object()`. Then we pass some of that data into the `sign_web3_message()` function from `WalletConnector.gd` to get an ECDSA signature, convert this signature into an EDDSA signature with the `GetApiKeyEDDSASig()` function from `PoseidonHelper.cs`, and then pass this signature into `Loopring.get_api_key()`.

If the signing process fails in WalletConnector, a `failed_to_sign` signal will be emitted.

Once you have an API key, you can query for the user's NFTs with `Loopring.get_token_balance()`, which requires a user wallet, API key, the smart contract address for the NFTs to check, and a boolean for if metadata should be fetched. This query gives you a response that contains an array of objects with several fields. The `metadata` field will appear if the `_get_metadata` parameter is true. See the function `get_tokens()` in `MainSceneManager.gd` for an example of this entire process and how to read the metadata.

## Notes
- Once Godot 4.0 is out, the SDK will need to be updated due to changes to coroutines and the replacement of `yield` with `await`. In the meantime, any calls to methods that wait for responses require checking if the return value is a GDScriptFunctionState, and if so, yield until completed.
- Godot 4.0's web exporting for C# is not working, so upgrading the SDK to 4.x will have to wait until those issues are fixed.

## Credits
Loopmon - This SDK is based on Loopmon's Unity package (https://github.com/LoopMonsters/LoopringUnity)

Fudgey - [PoseidonSharp](https://github.com/fudgebucket27/PoseidonSharp)

MetaBoy team - For advice and guidance on how to use the Loopring API and wallet connections.
