import { Fragment } from 'inferno';
import { useBackend } from '../backend';
import { Button, Box, Section, Tabs, NoticeBox } from '../components';

export const CommConsole = props => {
  const { act, data } = useBackend(props);
  const {
    authorized,
    eta,
    shuttle_status,
    ai_mode,
    shuttle_notice,
    id_name,
    captain,
    shuttle_market,
    link_lost,
  } = data;
  if (link_lost)
  {
    return (
      <Box>
        Unable to establish a connection.
        You&apos;re too far away from the station!
      </Box>);
  }

  if (!authorized) { return (
    <Section>
      <Button>Log In</Button>
    </Section>);
  }
  else { return (
    <Fragment>
      {!!shuttle_notice && (<NoticeBox>{shuttle_notice}</NoticeBox>)}
      <Section buttons={(
        <Fragment>
          <Box>Logged in as: {id_name}</Box>
          <Button content="Log out" />
        </Fragment>)}>
        <Tabs>
          <Tabs.Tab label="Emergency Shuttle">
            Shuttle Call
            Shuttle Recall
          </Tabs.Tab>
          {!!captain && (
            <Tabs.Tab title="Captain Functions">
              Captain stuff
            </Tabs.Tab>)}
          {!!shuttle_market && (
            <Tabs.Tab title="Shuttle Market">
              Shuttle Buy List
            </Tabs.Tab>)}
          <Tabs.Tab label="Messages">
            Message List
          </Tabs.Tab>
          <Tabs.Tab label="SDN Control">
            Status Display Network Control
          </Tabs.Tab>
          <Tabs.Tab label="Alert Level Control">
            Change Alert Level
          </Tabs.Tab>
          <Tabs.Tab label="Long-range Communication">
            Centcom Message
            Linked Stat Message
          </Tabs.Tab>
          <Tabs.Tab label="Emergency Protocols">
            Req Nuke
            Unlock Maint
          </Tabs.Tab>
        </Tabs>
      </Section>
    </Fragment>);
  }
};
