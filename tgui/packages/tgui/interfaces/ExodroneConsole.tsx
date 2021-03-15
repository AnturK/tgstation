/* eslint-disable max-len */
import { useBackend, useLocalState } from '../backend';
import { BlockQuote, Box, Button, Dimmer, Divider, Icon, LabeledList, Modal, NoticeBox, ProgressBar, Section, Stack } from '../components';
import { Window } from '../layouts';
import { resolveAsset } from '../assets';
import { formatTime } from '../format';
import { capitalize } from 'common/string';
import { map, toKeyedArray } from '../../common/collections';
import { IconStack } from '../components/Icon';
import nt_logo from '../assets/bg-nanotrasen.svg';
import { MiningVendor } from './MiningVendor';


type ExplorationEventData = {
  name: string,
  ref: string
}

type FullEventData = {
  image: string,
  description: string,
  action_enabled: boolean,
  action_text: string,
  skippable: boolean,
  ignore_text: string,
  ref: string
}

type ChoiceData = {
  key: string,
  text: string
}

type AdventureData = {
  description: string,
  image: string,
  raw_image: string,
  choices: Array<ChoiceData>
}

type SiteData = {
  name: string,
  ref: string,
  description: string,
  coordinates: string,
  distance: number,
  band_info: Record<string, number>,
  revealed: boolean,
  point_scan_complete: boolean,
  deep_scan_complete: boolean,
  events: Array<ExplorationEventData>
}


enum DroneStatusEnum {
  Idle = "idle",
  Travel = "travel",
  Exploration = "exploration",
  Adventure = "adventure",
  Busy = "busy"
}

enum CargoType {
  Tool = "tool",
  Cargo = "cargo",
  Empty = "empty"
}

type CargoData = {
  type: CargoType,
  name: string
}

type DroneBasicData = {
  name: string,
  description: string,
  controlled: boolean,
  ref: string,
}

type ExodroneConsoleData = {
  signal_lost: boolean,
  drone: boolean,
  all_drones?: Array<DroneBasicData>
  drone_status?: DroneStatusEnum,
  drone_name?: string,
  drone_integrity?: number,
  drone_max_integrity?: number,
  drone_travel_coefficent?: number,
  drone_log?: Array<string>,
  configurable?: boolean,
  cargo?: Array<CargoData>,
  can_travel?: boolean,
  sites?: Array<SiteData>,
  site?: SiteData,
  travel_time?: number,
  travel_time_left?: number,
  wait_time_left?: number,
  wait_message?: string,
  event?: FullEventData,
  adventure_data?: AdventureData,
  // ui_static_data
  all_tools: Record<string, string>,
  all_bands: Record<string, string>
}

export const ExodroneConsole = (props, context) => {
  const { data } = useBackend<ExodroneConsoleData>(context);
  const {
    signal_lost,
  } = data;

  const [
    choosingTools,
    setChoosingTools,
  ] = useLocalState(context, 'choosingTools', false);

  return (
    <Window width={650} height={500}>
      {!!signal_lost && <SignalLostModal />}
      {!!choosingTools && <ToolSelectionModal />}
      <Window.Content>
        <ExodroneConsoleContent />
      </Window.Content>
    </Window>
  );
};

const SignalLostModal = (props, context) => {
  const { act } = useBackend(context);
  return (
    <Modal backgroundColor="red" textAlign="center" width={30} height={22} p={0} style={{ "border-radius": "5%" }}>
      <img src={nt_logo} width={64} height={64} />
      <Box backgroundColor="black" textColor="red" fontSize={2} style={{ "border-radius": "-10%" }}>CONNECTION LOST</Box>
      <Box p={2} italic>
        Connection to exploration drone interrupted.
        Please contact nearest Nanotrasen Exploration Division
        representative for further instructions.
      </Box>
      <Icon name="exclamation-triangle" textColor="black" size={5} />
      <Box><Button color="danger" style={{ "border": "1px solid black" }} onClick={() => act("confirm_signal_lost")}>Confirm</Button></Box>
    </Modal>);
};

const DroneSelectionSection = (props, context) => {
  const { act, data } = useBackend<ExodroneConsoleData>(context);
  const {
    all_drones,
  } = data;

  return (
    <Section scrollable fill title="Exploration Drone Listing">
      <Stack vertical>
        {all_drones.map(drone => (
          <>
            <Stack.Item grow key={drone.ref}>
              <Stack fill>
                <Stack.Item basis={10} fontFamily="monospace" fontSize="18px">
                  {drone.name}
                </Stack.Item>
                <Stack.Divider />
                <Stack.Item fontFamily="monospace" mt={0.8}>
                  {drone.description}
                </Stack.Item>
                <Stack.Item grow />
                <Stack.Divider mr={1} />
                <Stack.Item ml={0}>
                  {drone.controlled && (
                    "Controlled by another console."
                  ) || (
                    <Button
                      content="Assume Control"
                      icon="plug"
                      onClick={() => act("select_drone", { "drone_ref": drone.ref })} />
                  )}
                </Stack.Item>
              </Stack>
            </Stack.Item>
            <Stack.Divider />
          </>
        ))}
      </Stack>
    </Section>);
};


const ToolSelectionModal = (props, context) => {
  const { act, data } = useBackend<ExodroneConsoleData>(context);
  const {
    all_tools = {},
  } = data;

  const [
    choosingTools,
    setChoosingTools,
  ] = useLocalState(context, 'choosingTools', false);

  return (
    <Modal>
      <Stack fill vertical pr={2}>
        <Stack.Item>
          Select Tool:
        </Stack.Item>
        <Stack.Item>
          <Stack textAlign="center">
            {!!Object.keys(all_tools) && Object.keys(all_tools).map(tool_name => (
              <Stack.Item key={tool_name}>
                <Button onClick={() => {
                  setChoosingTools(false);
                  act("add_tool", { tool_type: tool_name });
                }} width={6} height={6}>
                  <Stack vertical>
                    <Stack.Item>
                      {capitalize(tool_name)}
                    </Stack.Item>
                    <Stack.Item ml={2.5}>
                      <Icon name={all_tools[tool_name]} size={3} />
                    </Stack.Item>
                  </Stack>
                </Button>
              </Stack.Item>
            )) || (
              <Stack.Item>
                <Button
                  content="Back" />
              </Stack.Item>
            )}
          </Stack>
        </Stack.Item>
      </Stack>
    </Modal>);
};

const EquipmentBox = (props, context) => {
  const { act, data } = useBackend<ExodroneConsoleData>(context);
  const {
    configurable,
    all_tools = {},
  } = data;
  const cargo = props.cargo;
  const boxContents = cargo => {
    switch (cargo.type) {
      case "tool": // Tool icon+Remove button if configurable
        return (
          <Stack direction="column">
            <Stack.Item grow>
              <Button
                height={4.7}
                width={4.7}
                tooltip={capitalize(cargo.name)}
                tooltipPosition="right"
                color="transparent">
                <Icon
                  color="white"
                  name={all_tools[cargo.name]}
                  size={3}
                  pl={1.5}
                  pt={2} />
              </Button>
            </Stack.Item>
            {!!configurable && (
              <Stack.Item mt={-9.4} textAlign="right">
                <Button
                  onClick={() => act("remove_tool", { tool_type: cargo.name })}
                  color="danger"
                  icon="minus"
                  tooltipPosition="right"
                  tooltip="Remove Tool" />
              </Stack.Item>)}
          </Stack>);
      case "cargo":// Jettison button.
        return (
          <Stack direction="column">
            <Stack.Item>
              <Button
                mt={0}
                height={4.7}
                width={4.7}
                tooltip={capitalize(cargo.name)}
                tooltipPosition="right"
                color="transparent">
                <Icon
                  color="white"
                  name="box"
                  size={3}
                  pl={2.2}
                  pt={2} />
              </Button>
            </Stack.Item>
            <Stack.Item mt={-9.4} textAlign="right">
              <Button
                onClick={() => act("jettison", { target_ref: cargo.ref })}
                color="danger"
                icon="minus"
                tooltipPosition="right"
                tooltip={`Jettison ${cargo.name}`} />
            </Stack.Item>
          </Stack>);
      case "empty":
        return "";
    }
  };
  return (<Box width={5} height={5} style={{ border: '2px solid black' }} textAlign="center">{boxContents(cargo)}</Box>);
};

const EquipmentGrid = (props, context) => {
  const { act, data } = useBackend<ExodroneConsoleData>(context);
  const {
    cargo,
    configurable,
  } = data;
  const [
    choosingTools,
    setChoosingTools,
  ] = useLocalState(context, 'choosingTools', false);
  return (
    <Stack vertical fill>
      <Stack.Item grow>
        <Section fill title="Controls">
          <Stack vertical textAlign="center">
            <Stack.Item >
              <Button
                fluid
                icon="plug"
                content="Disconnect"
                onClick={() => act('end_control')} />
            </Stack.Item>
            <Stack.Divider />
            <Stack.Item>
              <Button.Confirm
                fluid
                icon="bomb"
                content="Self-Destruct"
                color="bad"
                onClick={() => act('self_destruct')} />
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Cargo">
          <Stack.Item>
            {!!configurable && (
              <Button
                fluid
                color="average"
                icon="wrench"
                content="Install Tool"
                onClick={() => { setChoosingTools(true); }} />
            )}
          </Stack.Item>
          <Stack.Item>
            <Stack wrap="wrap" width={10}>
              {cargo.map(cargo_element =>
                (<EquipmentBox key={cargo_element.name} cargo={cargo_element} />))}
            </Stack>
          </Stack.Item>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const DroneStatus = (props, context) => {
  const { act, data } = useBackend<ExodroneConsoleData>(context);
  const {
    drone_integrity,
    drone_max_integrity,
  } = data;

  return (
    <Stack ml={-40}>
      <Stack.Item color="label" mt={0.2}>
        Integrity:
      </Stack.Item>
      <Stack.Item grow>
        <ProgressBar
          width="200px"
          ranges={{
            good: [0.7 * drone_max_integrity, drone_max_integrity],
            average: [0.4 * drone_max_integrity, 0.7 * drone_max_integrity],
            bad: [-Infinity, 0.4 * drone_max_integrity],
          }}
          value={drone_integrity}
          maxValue={drone_max_integrity} />
      </Stack.Item>
    </Stack>);
};

const NoSiteDimmer = () => {
  return (
    <Dimmer>
      <Stack textAlign="center" vertical>
        <Stack.Item>
          <Icon
            color="red"
            name="map"
            size={10}
          />
        </Stack.Item>
        <Stack.Item fontSize="18px" color="red">
          No Destinations.
        </Stack.Item>
        <Stack.Item basis={0} color="red">
          (Use the Scanner Array Console to find new locations.)
        </Stack.Item>
      </Stack>
    </Dimmer>
  );
};

const TravelTargetSelectionScreen = (props, context) => {
  // List of sites and eta travel times to each
  const { act, data } = useBackend<ExodroneConsoleData>(context);
  const {
    sites,
    site,
    can_travel,
    drone_travel_coefficent,
    all_bands,
    drone_status,
  } = data;

  const travel_cost = target_site => {
    if (site) {
      return Math.max(Math.abs(site.distance - target_site.distance), 1) * drone_travel_coefficent;
    }
    else {
      return target_site.distance * drone_travel_coefficent;
    }
  };
  const [
    choosingTools,
    setChoosingTools,
  ] = useLocalState(context, 'choosingTools', false);
  const [
    TravelDimmerShown,
    setTravelDimmerShown,
  ] = useLocalState(context, 'TravelDimmerShown', false);

  const travel_to = ref => {
    setTravelDimmerShown(false);
    act("start_travel", { "target_site": ref });
  };

  return (
    drone_status === "travel" && (
      <TravelDimmer />
    ) || (
      <Section
        title="Travel Destinations"
        fill
        scrollable
        buttons={
          <>
            {props.showCancelButton && (
              <Button
                ml={5}
                mr={0}
                content="Cancel"
                onClick={() => setTravelDimmerShown(false)} />
            )}
            <Box mt={props.showCancelButton && -3.5}>
              <DroneStatus />
            </Box>
          </>
        }>
        {((sites && !sites.length) && !choosingTools) && (
          <NoSiteDimmer />
        )}
        {site && (
          <Section
            mt={1}
            title="Home"
            buttons={
              <Box>
                <Button
                  mr={1}
                  content="Launch!"
                  onClick={() => travel_to(null)}
                  disabled={!can_travel} />
                ETA: {formatTime(site.distance * drone_travel_coefficent, "short")}
              </Box>
            }
          />
        )}
        {sites.filter(destination => !site || destination.ref !== site.ref).map(destination => (
          <Section
            key={destination.ref}
            title={destination.name}
            buttons={
              <>
                <Button
                  mr={1}
                  content="Launch!"
                  onClick={() => travel_to(destination.ref)}
                  disabled={!can_travel} />
                ETA: {formatTime(travel_cost(destination), "short")}
              </>
            }>
            <LabeledList>
              <LabeledList.Item label="Location">
                {destination.coordinates}
              </LabeledList.Item>
              <LabeledList.Item label="Description">
                {destination.description}
              </LabeledList.Item>
              <LabeledList.Divider />
              {Object.keys(all_bands).filter(band => (destination.band_info[band] !== undefined && destination.band_info[band] !== 0)).map(band => (<LabeledList.Item key={band} label={band}>{destination.band_info[band]}</LabeledList.Item>))}
            </LabeledList>
          </Section>
        ))}
      </Section>
    )
  );
};

const TravelDimmer = (props, context) => {
  const { act, data } = useBackend<ExodroneConsoleData>(context);
  const {
    travel_time,
    travel_time_left,
  } = data;
  return (
    <Section fill>
      <Dimmer>
        <Stack textAlign="center" vertical>
          <Stack.Item>
            <Icon
              color="yellow"
              name="route"
              size={10}
            />
          </Stack.Item>
          <Stack.Item fontSize="18px" color="yellow">
            Travel Time: {formatTime(travel_time_left)}
          </Stack.Item>
        </Stack>
      </Dimmer>
    </Section>
  );
};

const TimeoutScreen = (props, context) => {
  const { act, data } = useBackend<ExodroneConsoleData>(context);
  const {
    wait_time_left,
    wait_message,
  } = data;
  return (
    <Section fill>
      <Dimmer>
        <Stack textAlign="center" vertical>
          <Stack.Item>
            <Icon
              color="green"
              name="cog"
              size={10}
            />
          </Stack.Item>
          <Stack.Item fontSize="18px" color="green">
            {wait_message} ({formatTime(wait_time_left)})
          </Stack.Item>
        </Stack>
      </Dimmer>
    </Section>
  );
};

const ExplorationScreen = (props, context) => {
  const { act, data } = useBackend<ExodroneConsoleData>(context);
  const {
    site,
    event,
    sites,
  } = data;

  const [
    TravelDimmerShown,
    setTravelDimmerShown,
  ] = useLocalState(context, 'TravelDimmerShown', false);

  if (TravelDimmerShown)
  { return (<TravelTargetSelectionScreen showCancelButton />); }
  // List of repeatables, Explore button. Last found event popup and continue exploring. Return home button.
  return (
    <Section
      fill
      title="Exploration"
      buttons={
        <DroneStatus />
      }>
      <Stack vertical fill>
        <Stack.Item grow>
          <LabeledList>
            <LabeledList.Item label="Site">{site.name}</LabeledList.Item>
            <LabeledList.Item label="Location">{site.coordinates}</LabeledList.Item>
            <LabeledList.Item label="Description">{site.description}</LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Item align="center" grow>
          <Button
            content="Explore!"
            onClick={() => act("explore")} />
        </Stack.Item>
        {site.events.map(e => (
          <Stack.Item
            align="center"
            key={site.ref}
            grow>
            <Button
              content={capitalize(e.name)}
              onClick={() => act("explore_event", { target_event: e.ref })} />
          </Stack.Item>))}
        <Stack.Item align="center" grow>
          <Button
            content="Travel"
            onClick={() => setTravelDimmerShown(true)} />
        </Stack.Item>
      </Stack>
    </Section>);
};

const EventScreen = (props, context) => {
  const { act, data } = useBackend<ExodroneConsoleData>(context);
  const {
    drone_status,
    event,
  } = data;
  return (
    <Section
      fill
      title="Exploration"
      buttons={
        <DroneStatus />
      }>
      {(drone_status && drone_status === "busy") && (
        <TimeoutScreen />
      )}
      <Stack vertical fill textAlign="center">
        <Stack.Item>
          <Stack fill>
            <Stack.Item>
              <img src={resolveAsset(event.image)}
                height="125px"
                width="250px"
                style={{
                  '-ms-interpolation-mode': 'nearest-neighbor',
                }} />
            </Stack.Item>
            <Stack.Item >
              <BlockQuote
                style={{ "white-space": "pre-wrap" }}>
                {event.description}
              </BlockQuote>
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Divider />
        <Stack.Item grow>
          <Stack vertical fill >
            <Stack.Item grow />
            <Stack.Item grow>
              <Button
                content={event.action_text}
                disabled={!event.action_enabled}
                onClick={() => act("start_event")} />
            </Stack.Item>
            {!!event.skippable && (
              <Stack.Item mt={2}>
                <Button
                  content={event.ignore_text}
                  onClick={() => act("skip_event")} />
              </Stack.Item>
            )}
            <Stack.Item grow />
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>);
};

const AdventureScreen = (props, context) => {
  const { act, data } = useBackend<ExodroneConsoleData>(context);
  const {
    adventure_data,
  } = data;
  return (
    <Section
      fill
      title="Exploration"
      buttons={<DroneStatus />}>
      <Stack>
        <Stack.Item>
          <BlockQuote style={{ "white-space": "pre-wrap" }}>{adventure_data.description}</BlockQuote>
        </Stack.Item>
        <Stack.Divider />
        <Stack.Item>
          <img
            src={adventure_data.raw_image ? adventure_data.raw_image : resolveAsset(adventure_data.image)}
            height="100px"
            width="200px"
            style={{
              '-ms-interpolation-mode': 'nearest-neighbor',
            }} />
          <Stack vertical>
            <Stack.Divider />
            <Stack.Item grow />
            {!!adventure_data.choices && adventure_data.choices.map(choice => (
              <Stack.Item key={choice.key}>
                <Button
                  fluid
                  content={choice.text}
                  textAlign="center"
                  onClick={() => act('adventure_choice', { choice: choice.key })} />
              </Stack.Item>
            ))}
            <Stack.Item grow />
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>);
};

const DroneScreen = (props, context) => {
  const { act, data } = useBackend<ExodroneConsoleData>(context);
  const {
    drone_status,
    event,
  } = data;
  switch (drone_status) {
    case "busy":
      return (<TimeoutScreen />);
    case "idle":
    case "travel":
      return (<TravelTargetSelectionScreen />);
    case "adventure":
      return (<AdventureScreen />);
    case "exploration":
      if (event)
      { return (<EventScreen />); }
      else
      { return (<ExplorationScreen />); }
  }
};

const ExodroneConsoleContent = (props, context) => {
  const { act, data } = useBackend<ExodroneConsoleData>(context);
  const {
    drone,
    drone_name,
    drone_log,
  } = data;

  if (!drone)
  { return (<DroneSelectionSection />); }

  return (
    <Stack fill vertical>
      <Stack.Item grow>
        <Stack vertical fill grow={2}>
          <Stack.Item grow>
            <Stack fill>
              <Stack.Item>
                <EquipmentGrid />
              </Stack.Item>
              <Stack.Item grow basis={0}>
                <DroneScreen />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item height={10}>
        <Section title="Drone Log" fill scrollable>
          <LabeledList>
            {drone_log.map((log_line, ix) => (
              <LabeledList.Item key={log_line} label={`Entry ${ix+1 }`}>
                {log_line}
              </LabeledList.Item>))}
          </LabeledList>
        </Section>
      </Stack.Item>
    </Stack>
  );
};
