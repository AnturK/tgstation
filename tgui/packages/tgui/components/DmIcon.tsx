import { useEffect } from 'react';

import { resolveAsset } from '../assets';
import { fetchRetry } from '../http';
import { Box, BoxProps } from './Box';
import { Image } from './Image';

enum Direction {
  NORTH = 1,
  SOUTH = 2,
  EAST = 4,
  WEST = 8,
  NORTHEAST = NORTH | EAST,
  NORTHWEST = NORTH | WEST,
  SOUTHEAST = SOUTH | EAST,
  SOUTHWEST = SOUTH | WEST,
}

type Props = BoxProps & {
  icon: string;
  icon_state: string;
  direction?: Direction;
  movement?: boolean;
  frame?: number;
};

type IconRefMap = { [icon: string]: string };

let refMap: IconRefMap | undefined;

export function DmIcon(props: Props) {
  const { icon, icon_state, direction, movement, frame, className, ...rest } =
    props;

  const get_ref = (name: string) => {
    if (refMap) {
      return refMap[name];
    }
  };

  useEffect(() => {
    if (!refMap) {
      fetchRetry(resolveAsset('icon_ref_map.json')).then((response) =>
        response.json().then((value) => (refMap = value)),
      );
    }
  });

  const icon_ref = get_ref(icon);
  if (!icon_ref) {
    return <Box>Oh god it broke</Box>;
  }
  const dir = direction || Direction.SOUTH;
  const mov = movement || false;
  const frame_used = frame || 1;
  // skipping sheet for now

  const query = `${icon_ref}?state=${icon_state}&dir=${dir}&movement=${mov}&frame=${frame_used}`;
  // logger.log(query);
  return <Image src={query} {...rest} />;
}
