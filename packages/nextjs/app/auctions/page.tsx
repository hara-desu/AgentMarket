import Auctions from "./_components/Auctions";
import type { NextPage } from "next";
import { getMetadata } from "~~/utils/scaffold-eth/getMetadata";

export const metadata = getMetadata({
  title: "Auctions",
  description: "Trade AI agents with English or Dutch auction.",
});

const Debug: NextPage = () => {
  return (
    <>
      <div className="text-center bg-secondary p-5">
        <h1 className="text-4xl my-0">Explore auctions and participate!</h1>
      </div>
      <div className="p-10">
        <Auctions />
      </div>
    </>
  );
};

export default Debug;
