import axios from "axios";

const pinataKey = process.env.NEXT_PUBLIC_PINATA_API_KEY;
const pinataSecret = process.env.NEXT_PUBLIC_PINATA_API_SECRET;

export const pinJsonToIpfs = async JSONBody => {
  const url = `https://api.pinata.cloud/pinning/pinJSONToIPFS`;
  //making axios POST request to Pinata ⬇️
  return axios
    .post(url, JSONBody, {
      headers: {
        pinata_api_key: pinataKey,
        pinata_secret_api_key: pinataSecret,
      },
    })
    .then(function (response) {
      return {
        success: true,
        pinataUrl: "https://gateway.pinata.cloud/ipfs/" + response.data.IpfsHash,
      };
    })
    .catch(function (error) {
      console.log(error);
      return {
        success: false,
        message: error.message,
      };
    });
};

export const pinFileToIpfs = async file => {
  const url = `https://api.pinata.cloud/pinning/pinFileToIPFS`;

  const formData = new FormData();
  formData.append("file", file); // Append the file

  return axios
    .post(url, formData, {
      headers: {
        "Content-Type": "multipart/form-data", // Important!
        pinata_api_key: pinataKey,
        pinata_secret_api_key: pinataSecret,
      },
    })
    .then(response => {
      return {
        success: true,
        pinataUrl: `https://gateway.pinata.cloud/ipfs/${response.data.IpfsHash}`,
      };
    })
    .catch(error => {
      console.error("Failed to upload file to IPFS:", error);
      return {
        success: false,
        message: error.message,
      };
    });
};
