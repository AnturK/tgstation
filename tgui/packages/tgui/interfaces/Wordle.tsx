/* eslint-disable max-len */
import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';
import { Box, Button, Flex, KeyListener, NoticeBox, Table } from '../components';
import { KeyEvent } from '../events';
import { KEY_BACKSPACE, KEY_ENTER } from 'common/keycodes';

// TODO : use proper css classes
// TODO : Fix the thing where pressing enter keeps focus on word suggest

enum GuessResult{
  Unknown,
  Correct,
  Misplaced,
  Wrong
}

type GuessData = {
  guess: string;
  result: GuessResult[];
}

type WordleData = {
  guesses: GuessData[];
  guessesLeft: number;
  wordLength: number;
  alphabet: Record<string, GuessResult>;
  message: string;
  last_invalid_guess : string | null;
  finished: boolean;
};

export const Wordle = (props, context) => {
  const { act, data } = useBackend<WordleData>(context);
  const { guesses, guessesLeft, message, last_invalid_guess, finished } = data;
  const [currentGuess, setCurrentGuess] = useLocalState(context, "currentGuess", "");

  const handleKey = (key: KeyEvent) => {
    if (finished) {
      return;
    }
    key.event.preventDefault();
    if (key.isDown()) {
      if (key.code === KEY_ENTER && currentGuess.length === data.wordLength) {
        const guess = currentGuess;
        setCurrentGuess("");
        act("guess", { guess });
      } else if (key.code === KEY_BACKSPACE && currentGuess.length > 0) {
        setCurrentGuess(currentGuess.substr(0, currentGuess.length - 1));
      } else if (
        key.code >= 48
        && key.code <= 90
        && currentGuess.length < data.wordLength) {
        setCurrentGuess(currentGuess.concat(String.fromCharCode(key.code)));
      }
    }

  };

  const paddedCurrentGuess = () => {
    return { guess: currentGuess.padEnd(data.wordLength, "_"), result: Array<GuessResult>(data.wordLength).fill(GuessResult.Unknown) };
  };

  const suggestionButton = <Button onClick={() => act("suggest_word")}>Sugest &quot;{last_invalid_guess}&quot; as a new word</Button>;

  return (
    <Window>
      <Window.Content>
        <KeyListener
          onKey={key => handleKey(key)}
        />
        {!!message && (<NoticeBox>{message} {last_invalid_guess !== null ? suggestionButton : ""}</NoticeBox>)}
        <Flex align="center" justify="center" direction="column">
          <Flex.Item>
            <Table>
              {guesses.map((guess, i) => <WordleGuessLine key={`guess_${i}`} guess={guess} />)}
              {guessesLeft > 0 && <WordleGuessLine guess={paddedCurrentGuess()} />}
              {guessesLeft > 1 && Array(guessesLeft-1).fill(1).map((_, i) => <WordleGuessLine key={`future_guess_${i}`} />)}
            </Table>
          </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  );
};

type GuessLineProps = {
  guess? : GuessData;
}

const WordleGuessLine = (props: GuessLineProps, context: any) => {
  const { act, data } = useBackend<WordleData>(context);
  const guess_string = props.guess?.guess || "_".repeat(data.wordLength) as string;
  const letters = guess_string.split('');
  const guesses = props.guess?.result || Array(data.wordLength).fill(GuessResult.Unknown);
  return (
    <Table.Row>
      {letters.map((guess, i) =>
        (<LetterBox
          key={i}
          letter={guess}
          state={guesses[i]} />))}
    </Table.Row>
  );
};

const LetterBox = (props: { letter: string, state: GuessResult}, context: any) => {
  const { letter, state } = props;
  const guess_color = (state) => {
    switch (state) {
      case GuessResult.Unknown:
        return "#121213";
      case GuessResult.Correct:
        return "#f5793a";
      case GuessResult.Misplaced:
        return "#85c0f9";
      case GuessResult.Wrong:
        return "#3a3a3c";
    }
  };
  return (
    <Table.Cell
      width={5}
      height={5}
      backgroundColor={guess_color(state)}
      style={{ "border": "1px solid black", "vertical-align": "middle" }}>
      <Box
        bold
        textAlign="center"
        textColor="white"
        fontSize="2">
        {letter}
      </Box>
    </Table.Cell>);
};

