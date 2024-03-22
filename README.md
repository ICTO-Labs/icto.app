# ICTO - IC Token Operations

To get started, you might want to explore the project directory structure and the default configuration file. Working with this project in your development environment will not affect any production deployment or identity tokens.

To learn more before you start working with icto.app, see the following documentation available online:

- [Quick Start](https://sdk.dfinity.org/docs/quickstart/quickstart-intro.html)
- [SDK Developer Tools](https://sdk.dfinity.org/docs/developers-guide/sdk-guide.html)
- [Motoko Programming Language Guide](https://sdk.dfinity.org/docs/language-guide/motoko.html)
- [Motoko Language Quick Reference](https://sdk.dfinity.org/docs/language-guide/language-manual.html)
- [JavaScript API Reference](https://erxue-5aaaa-aaaab-qaagq-cai.raw.ic0.app)



## Running the project locally

```bash
# Starts the replica, running in the background
dfx start --background

# Create all canister
dfx canister create --all

# Deploys your all canisters to the replica and generates candid interface
dfx deploy
```
Once the job completes, your application will be available at `http://localhost:8000?canisterId={canister_id}`.

Additionally, if you are making frontend changes, you can start a development server with

```bash
# Install all node_modules
npm i

# Start dev server
npm run dev
```

Which will start a server at `http://localhost:5173`, proxying API requests to the replica at port 8000.


`Frontend`: You can find all config params in:
```
./frontend/config/index.js
```

## Live version
ICTO App: https://icto.app
Documents: https://docs.icto.app
Twitter(X): https://x.com/icto_app
