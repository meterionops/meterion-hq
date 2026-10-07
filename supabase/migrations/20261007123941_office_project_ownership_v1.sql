-- Additive ownership for the existing 21 verified Meterion coordination projects.
-- No default: future projects require explicit ownership; unknown ownership is denied.
alter table public.control_room_projects add column organization_id uuid;
update public.control_room_projects set organization_id='2e737407-7aa5-4567-a8bf-0d110cfef2ae'
where id in ('8eb82784-28a1-4364-a1c2-c2f63b316c7a',
'9db67f9e-3a12-443d-ad39-fa9242bbc8e8',
'9c1794b6-16b6-471d-be73-150fefecb5f8',
'171b3a31-575f-4883-a0fd-009ed304dcc7',
'b0d60a54-12bc-4e9a-aa3b-b3bac4d8a5cd',
'fdf65ff0-bee1-49ea-99d9-1d36ade72a28',
'16815d80-043b-4d37-90ec-eacbe35e3ca6',
'f6494cfc-4e74-4947-92e8-a5103bc704f3',
'392f72ee-6a2d-4a33-a6c3-2d68f068ebf8',
'154a3b9a-7340-4e89-a083-0d6a9ce391b9',
'ab19a120-c4a8-4e76-9425-87fb268859bf',
'5cecafcd-df88-47fc-9d1d-aa2f6ab7e50e',
'25ab8f92-1553-42e8-b2e4-6c11a9d46d30',
'85707b25-4efc-4f44-be2d-7dfe109b30b5',
'ce8b5449-c8e3-428b-951a-8415124888eb',
'213d7445-46bc-4836-9878-0d4ce56d1c16',
'1b1dbfa4-43be-4221-b923-c74fb0a13c0a',
'11a581d2-5152-4f3a-8b40-76af3ec723e6',
'b587c6f9-8827-4651-8033-a9b8c2d0445b',
'136bfad7-ea31-4e47-8545-0c5126497794',
'f2cb28bc-2fbe-4f39-8651-12af0b80671a');
comment on column public.control_room_projects.organization_id is 'Company Auth organization identity. No cross-database FK; current membership checked by the Owner bridge. Unassigned rows are excluded from Office.';

