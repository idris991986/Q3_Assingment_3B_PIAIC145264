require("@nomiclabs/hardhat-waffle");
require(`dotenv`).config();

const Private_Key = process.env.PRIVATE_KEY;

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.0",
  networks:{
    ropsten:{
      url: process.env.INFURA_API_KEY,
      accounts: [`0x${Private_Key}`]
    }
  }
};
