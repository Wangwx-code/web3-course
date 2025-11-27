export function getCurrentNetworkName(): string {
  return process.env.HARDHAT_NETWORK ?? "hardhat";
}