import { Fragment } from 'inferno';
import { useBackend } from '../backend';
import { Button, Box, ProgressBar } from '../components';

export const ArcadeBattle = props => {
  const { act, data } = useBackend(props);
  const {
    player_hp,
    player_max_hp,
    player_mp,
    player_max_mp,
    message,
    enemy_hp,
    enemy_max_hp,
    enemy_name,
    gameover,
  } = data;
  return (
    <Box>
      <h1>{enemy_name}</h1>
      <ProgressBar 
        value={enemy_hp}
        minValue={0}
        maxValue={enemy_max_hp}
        ranges={{
          good: [0.7*enemy_max_hp, Infinity],
          average: [0.5*enemy_max_hp, 0.7*enemy_max_hp],
          bad: [-Infinity, 0.5*enemy_max_hp],
        }}>
        {enemy_hp}
      </ProgressBar>
      <p>{message}</p>
      <ProgressBar 
        value={player_hp}
        minValue={0}
        maxValue={player_max_hp}
        ranges={{
          good: [0.7*player_max_hp, Infinity],
          average: [0.5*player_max_hp, 0.7*player_max_hp],
          bad: [-Infinity, 0.5*player_max_hp],
        }}>
        {player_hp}
      </ProgressBar>
      <ProgressBar 
        value={player_mp}
        minValue={0}
        maxValue={player_max_mp}
        color="blue">
        {player_mp}
      </ProgressBar>
      {!!gameover && (
        <Fragment>
          <Button onClick={() => act("attack")}>Attack</Button>
          <Button onClick={() => act("heal")}>Heal</Button>
          <Button onClick={() => act("recharge")}>Recharge</Button>
        </Fragment>
      )}
      {!gameover && (
        <Button onClick={() => act("new_game")}>New Game</Button>
      )}
    </Box>
  );
};
