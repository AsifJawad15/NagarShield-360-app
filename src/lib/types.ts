export type Role = 'executive' | 'department_head' | 'supervisor' | 'field_employee' | 'survey_operator'
export type IncidentStatus = 'needs_review' | 'verified' | 'assigned' | 'acknowledged' | 'in_progress' | 'action_submitted' | 'verification_pending' | 'resolved' | 'dismissed'
export type TaskStatus = 'assigned' | 'acknowledged' | 'in_progress' | 'action_submitted' | 'resolved'
export type Priority = 'low' | 'moderate' | 'high' | 'critical'
export type DetectionType = 'DRAIN_OBSTRUCTION' | 'STANDING_WATER' | 'WASTE' | 'FOOTPATH_OBSTRUCTION' | 'ACCESS_OBSTRUCTION' | 'WATER_CONTAINER'

export interface OfficialProfile {
  id: string
  display_name: string
  role: Role
  department_id: string | null
  team_id: string | null
  departments?: { name_bn: string } | null
}

export interface Incident {
  id: string
  observation_id: string | null
  code: string
  title_bn: string
  description_bn: string
  hazard: DetectionType
  status: IncidentStatus
  priority: Priority
  score: number
  area_bn: string
  lat: number
  lng: number
  escalated: boolean
  before_key: string | null
  after_key: string | null
  created_at: string
  updated_at: string
  department_id: string
}

export interface DemoTask {
  id: string
  incident_id: string
  department_id: string
  team_id: string | null
  assignee_id: string | null
  status: TaskStatus
  note: string | null
  completion_note: string | null
  created_at: string
  updated_at: string
  departments?: { name_bn: string } | null
  profiles?: { display_name: string } | null
}

export interface Detection {
  type: DetectionType
  label_bn: string
  confidence: number
  box: [number, number, number, number]
}

export interface Scenario {
  id: string
  title_bn: string
  summary_bn: string
  kind: 'image' | 'video'
  hazard: DetectionType
  area_bn: string
  media_key: string
  detections: Detection[]
  factors: ScoreFactors
}

export interface ScoreFactors {
  drain: number
  vector: number
  waste: number
  access: number
  recurrence: number
  evidence: number
  bonus: number
}
