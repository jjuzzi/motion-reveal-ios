import "./index.css";
import { Composition } from "remotion";
import { IslandDiscRitual } from "./Composition";
import { LaunchFlipStudy } from "./LaunchFlipStudy";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="IslandDiscRitual"
        component={IslandDiscRitual}
        durationInFrames={132}
        fps={30}
        // eslint-disable-next-line @remotion/even-dimensions -- 393x852 matches the iPhone reference viewport.
        width={393}
        height={852}
      />
      <Composition
        id="LaunchFlipStudy"
        component={LaunchFlipStudy}
        durationInFrames={96}
        fps={30}
        // eslint-disable-next-line @remotion/even-dimensions -- 393x852 matches the iPhone reference viewport.
        width={393}
        height={852}
      />
    </>
  );
};
