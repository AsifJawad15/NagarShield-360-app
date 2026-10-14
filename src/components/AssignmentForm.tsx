'use client'

import { useState } from 'react'
import { performWorkflowAction } from '@/app/actions/workflow'
import type { Role } from '@/src/lib/types'

type Department = { id: string; name_bn: string }
type Employee = { id: string; display_name: string; department_id: string; team_id: string | null }

export function AssignmentForm({ incidentId, role, departmentId, teamId, departments, employees }: {
  incidentId: string
  role: Role
  departmentId: string | null
  teamId: string | null
  departments: Department[]
  employees: Employee[]
}) {
  const allowedDepartments = role === 'executive' ? departments : departments.filter(item => item.id === departmentId)
  const [selectedDepartment, setSelectedDepartment] = useState(allowedDepartments[0]?.id || '')
  const [assigneeId, setAssigneeId] = useState('')
  const availableEmployees = employees.filter(item => item.department_id === selectedDepartment && (role !== 'supervisor' || item.team_id === teamId))
  const assignee = availableEmployees.find(item => item.id === assigneeId)

  return <form action={performWorkflowAction} className="assignment-form">
    <h3>এই ঘটনার কাজ কাউকে দিন</h3>
    <input type="hidden" name="action" value="assign_task"/>
    <input type="hidden" name="target" value={incidentId}/>
    <input type="hidden" name="return_to" value={`/incidents/${incidentId}`}/>
    <input type="hidden" name="team_id" value={assignee?.team_id || ''}/>
    <div className="form-grid">
      <label>বিভাগ
        <select name="department_id" required value={selectedDepartment} onChange={event => {
          setSelectedDepartment(event.target.value)
          setAssigneeId('')
        }}>
          {allowedDepartments.map(item => <option key={item.id} value={item.id}>{item.name_bn}</option>)}
        </select>
      </label>
      <label>মাঠকর্মী
        <select name="assignee_id" required value={assigneeId} onChange={event => setAssigneeId(event.target.value)}>
          <option value="" disabled>মাঠকর্মী নির্বাচন করুন</option>
          {availableEmployees.map(item => <option key={item.id} value={item.id}>{item.display_name}</option>)}
        </select>
      </label>
      <label className="assignment-note">কী করতে হবে
        <input name="note" maxLength={1000} placeholder="যেমন: জায়গাটি দেখে ড্রেন পরিষ্কার করুন"/>
      </label>
    </div>
    {availableEmployees.length === 0 && <p className="field-error">এই বিভাগে দায়িত্ব দেওয়ার মতো মাঠকর্মী নেই।</p>}
    <button className="button-dark" type="submit" disabled={!assignee}>দায়িত্ব দিন</button>
    <p className="help-text">নির্বাচিত মাঠকর্মীর দল অনুযায়ী দায়িত্বটি দেওয়া হবে।</p>
  </form>
}
