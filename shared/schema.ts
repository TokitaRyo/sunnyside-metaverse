import { schema, t, type SchemaType } from "@colyseus/schema";

// Schema Builder (schema() / t.*) に統一。判断理由は docs/decisions.md 参照。
export const Player = schema({
  name: t.string(),
  hair: t.string(),
  x: t.float32(),
  y: t.float32(),
  flipX: t.boolean(),
  /** "idle" | "walk" | "run" | エモートID */
  action: t.string(),
});
export type Player = SchemaType<typeof Player>;

export const MainRoomState = schema({
  players: t.map(Player),
});
export type MainRoomState = SchemaType<typeof MainRoomState>;
