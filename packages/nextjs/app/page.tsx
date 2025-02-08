"use client";

import { useState } from "react";
import { OwnedAgents } from "./account/OwnedAgents";
import { Participation } from "./account/Participation";
import type { NextPage } from "next";

const Home: NextPage = () => {
  const [selectedComponent, setSelectedComponent] = useState("OwnedAgents");

  const handleSwitch = (component: string) => {
    setSelectedComponent(component);
  };

  return (
    <div className="flex flex-col gap-y-6 py-3 justify-center items-center">
      <div className="px-2">
        <h1 className="text-center text-2xl">
          <span className="block text-4xl mb-2">Agent Market</span>
          Decentralized marketplace for AI agents.
        </h1>
      </div>

      <div className="flex flex-row gap-5 w-full max-w-7xl pb-1 px-1 flex-wrap">
        <button
          className={`btn btn-secondary btn-md font-light text-lg hover:border-transparent`}
          onClick={() => handleSwitch("OwnedAgents")}
        >
          Owned AI agents
        </button>
        <button
          className={`btn btn-secondary btn-md font-light text-lg hover:border-transparent`}
          onClick={() => handleSwitch("Participation")}
        >
          Participating Auctions
        </button>
        {selectedComponent === "OwnedAgents" && <OwnedAgents />}
        {selectedComponent === "Participation" && <Participation />}
      </div>
    </div>
  );
};

export default Home;
