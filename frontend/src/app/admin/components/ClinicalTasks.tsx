"use client"

import React, { useState } from "react"
import {
  Search,
  Filter,
  Plus,
  X,
  Sparkles,
  Clock,
  CheckCircle2,
  Wrench,
  Activity,
  User,
  AlertCircle,
  FileText,
  ShieldAlert
} from "lucide-react"
import { MedicalTask } from "../mockData"

interface TasksProps {
  tasks: MedicalTask[]
  onAddTask: (task: MedicalTask) => void
  onUpdateTask: (task: MedicalTask) => void
  isCreateOpen: boolean
  setIsCreateOpen: (open: boolean) => void
}

export function ClinicalTasks({
  tasks,
  onAddTask,
  onUpdateTask,
  isCreateOpen,
  setIsCreateOpen
}: TasksProps) {
  const [searchQuery, setSearchQuery] = useState("")
  const [typeFilter, setTypeFilter] = useState("all")

  // Form State for dispatch task
  const [newBedId, setNewBedId] = useState("")
  const [newTaskDesc, setNewTaskDesc] = useState("")
  const [newPriority, setNewPriority] = useState<MedicalTask["priority"]>("medium")
  const [newType, setNewType] = useState<MedicalTask["type"]>("nursing")
  const [newAssignee, setNewAssignee] = useState("Nurse Sarah Jenkins")

  const nursesList = ["Nurse Sarah Jenkins", "Nurse David Vance", "Nurse Maria Gomez", "Nurse John Doe", "Nurse Chloe Adams"]

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault()
    if (!newBedId || !newTaskDesc) return

    const now = new Date()
    const timestamp = now.toLocaleTimeString("en-US", {
      hour: "2-digit",
      minute: "2-digit",
      hour12: true
    })

    const newTask: MedicalTask = {
      id: `TSK-${Math.floor(1000 + Math.random() * 9000)}`,
      bedId: newBedId,
      task: newTaskDesc,
      priority: newPriority,
      assignedTo: newAssignee,
      status: "pending",
      type: newType,
      timestamp
    }

    onAddTask(newTask)

    // Reset Form
    setNewBedId("")
    setNewTaskDesc("")
    setNewPriority("medium")
    setNewType("nursing")
    setNewAssignee("Nurse Sarah Jenkins")
    setIsCreateOpen(false)
  }

  const handleStatusChange = (task: MedicalTask, nextStatus: MedicalTask["status"]) => {
    onUpdateTask({
      ...task,
      status: nextStatus
    })
  }

  // Filter tasks
  const filteredTasks = tasks.filter((t) => {
    const matchesSearch =
      t.bedId.includes(searchQuery) ||
      t.task.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.assignedTo.toLowerCase().includes(searchQuery.toLowerCase())
    
    const matchesType = typeFilter === "all" || t.type === typeFilter

    return matchesSearch && matchesType
  })

  // Group stats
  const pendingCount = tasks.filter(t => t.status === "pending").length
  const progressCount = tasks.filter(t => t.status === "in-progress").length
  const completedCount = tasks.filter(t => t.status === "completed").length

  const getPriorityColor = (priority: MedicalTask["priority"]) => {
    switch (priority) {
      case "emergency":
        return "bg-rose-100 text-rose-700 border-rose-200 font-black animate-pulse"
      case "high":
        return "bg-amber-50 text-amber-700 border-amber-100 font-semibold"
      case "medium":
        return "bg-blue-50 text-blue-700 border-blue-100"
      case "low":
        return "bg-gray-50 text-gray-700"
      default:
        return "bg-gray-50 text-gray-700"
    }
  }

  const getTaskIcon = (type: MedicalTask["type"]) => {
    switch (type) {
      case "nursing":
        return <Activity className="h-4 w-4 text-emerald-500" />
      case "lab-test":
        return <FileText className="h-4 w-4 text-blue-500" />
      case "pharmacy":
        return <Sparkles className="h-4 w-4 text-purple-500" />
      case "sanitization":
        return <Wrench className="h-4 w-4 text-amber-500" />
      default:
        return <AlertCircle className="h-4 w-4 text-gray-500" />
    }
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Service stats grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white rounded-2xl border border-[#E8ECEB] p-5 shadow-xs flex items-center justify-between">
          <div>
            <span className="text-[10px] text-[#8AA098] font-bold uppercase tracking-wider block">Clinical backlog</span>
            <h3 className="text-2xl font-black text-[#0B2B26] mt-1">{pendingCount} pending</h3>
            <span className="text-[10px] text-rose-600 font-semibold block mt-1">Requires immediate attention</span>
          </div>
          <div className="w-10 h-10 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center font-bold">
            <Clock className="h-5 w-5 animate-pulse" />
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-[#E8ECEB] p-5 shadow-xs flex items-center justify-between">
          <div>
            <span className="text-[10px] text-[#8AA098] font-bold uppercase tracking-wider block">In Treatment Process</span>
            <h3 className="text-2xl font-black text-[#0B2B26] mt-1">{progressCount} in progress</h3>
            <span className="text-[10px] text-emerald-600 font-semibold block mt-1">Attending nurses active</span>
          </div>
          <div className="w-10 h-10 rounded-xl bg-[#EEF4F1] text-emerald-600 flex items-center justify-center font-bold">
            <User className="h-5 w-5" />
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-[#E8ECEB] p-5 shadow-xs flex items-center justify-between">
          <div>
            <span className="text-[10px] text-[#8AA098] font-bold uppercase tracking-wider block">Resolved Orders Today</span>
            <h3 className="text-2xl font-black text-[#0B2B26] mt-1">{completedCount} complete</h3>
            <span className="text-[10px] text-emerald-600 font-semibold block mt-1">High efficiency turnover</span>
          </div>
          <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
            <CheckCircle2 className="h-5 w-5" />
          </div>
        </div>
      </div>

      {/* Control filters bar */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 bg-white p-6 rounded-3xl border border-[#E8ECEB] shadow-xs">
        <div className="flex items-center gap-2 bg-[#F6F8F7] border border-[#D7E2DC] px-3.5 py-2 rounded-xl w-full md:w-80">
          <Search className="h-4 w-4 text-[#8AA098]" />
          <input
            type="text"
            placeholder="Search orders by Bed ID, Nurse, details..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="bg-transparent border-0 outline-none text-xs text-[#0B2B26] w-full placeholder:text-[#9CAEA6] focus:ring-0"
          />
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Service type filters */}
          <div className="flex bg-[#F6F8F7] border border-[#D7E2DC] p-1 rounded-xl">
            {["all", "nursing", "lab-test", "pharmacy", "sanitization"].map((type) => (
              <button
                key={type}
                onClick={() => setTypeFilter(type)}
                className={`px-3.5 py-1.5 rounded-lg text-xs font-bold capitalize transition-all ${
                  typeFilter === type
                    ? "bg-emerald-600 text-white shadow-xs"
                    : "text-[#6B8078] hover:text-[#12463E]"
                }`}
              >
                {type.replace("-", " ")}
              </button>
            ))}
          </div>

          <button
            onClick={() => setIsCreateOpen(true)}
            className="h-10 px-4 rounded-xl bg-emerald-500 hover:bg-emerald-600 text-white font-bold text-xs shadow-md shadow-emerald-500/10 transition-all flex items-center gap-2"
          >
            <Plus className="h-4 w-4" />
            Dispatch Order
          </button>
        </div>
      </div>

      {/* Task List Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredTasks.map((task) => (
          <div
            key={task.id}
            className={`bg-white rounded-3xl border border-[#E8ECEB] p-5 shadow-xs hover:shadow-md transition-all flex flex-col justify-between relative overflow-hidden ${
              task.status === "completed" ? "opacity-75" : ""
            }`}
          >
            {/* Ribbon or top status */}
            <div>
              <div className="flex items-center justify-between">
                <span className="text-[10px] text-[#8AA098] font-bold tracking-widest">{task.id}</span>
                <span className={`inline-flex items-center px-2 py-0.5 rounded-md border text-[9px] capitalize ${getPriorityColor(task.priority)}`}>
                  {task.priority === "emergency" && <ShieldAlert className="h-3 w-3 mr-1 animate-bounce" />}
                  {task.priority}
                </span>
              </div>

              {/* Task Title & Description */}
              <div className="flex items-start gap-3 mt-4">
                <div className="p-2.5 bg-[#EEF4F1] border border-[#D7E2DC] rounded-xl shrink-0">
                  {getTaskIcon(task.type)}
                </div>
                <div>
                  <h4 className="text-sm font-bold text-[#0B2B26]">Bed {task.bedId}</h4>
                  <p className="text-xs text-[#6B8078] mt-1 leading-relaxed">{task.task}</p>
                </div>
              </div>
            </div>

            {/* Footer with assignee & controls */}
            <div className="mt-6 pt-4 border-t border-[#F6F8F7] flex items-center justify-between">
              <div>
                <span className="text-[9px] text-[#8AA098] block">Attending Nurse</span>
                <span className="text-xs font-bold text-[#0B2B26] mt-0.5 block">{task.assignedTo}</span>
              </div>

              {/* Action State buttons */}
              <div className="flex items-center gap-2">
                {task.status === "pending" && (
                  <button
                    onClick={() => handleStatusChange(task, "in-progress")}
                    className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white text-[10px] font-bold rounded-lg transition-all"
                  >
                    Start Care
                  </button>
                )}
                {task.status === "in-progress" && (
                  <button
                    onClick={() => handleStatusChange(task, "completed")}
                    className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white text-[10px] font-bold rounded-lg transition-all"
                  >
                    Resolve
                  </button>
                )}
                {task.status === "completed" && (
                  <span className="text-[10px] text-emerald-600 font-bold bg-emerald-50 px-2 py-1 rounded-md border border-emerald-100 flex items-center gap-1.5">
                    <CheckCircle2 className="h-3 w-3" /> Resolved
                  </span>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Dispatch Order Modal */}
      {isCreateOpen && (
        <>
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 transition-opacity" onClick={() => setIsCreateOpen(false)} />
          
          <div className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md bg-white rounded-3xl border border-[#E8ECEB] shadow-2xl p-6 z-50 animate-fade-in">
            <div className="flex items-center justify-between border-b border-[#E8ECEB] pb-4">
              <div>
                <h3 className="text-lg font-bold text-[#0B2B26]">Dispatch Care Request</h3>
                <p className="text-xs text-[#8AA098]">Create nursing orders, lab tests, or sanitization tasks</p>
              </div>
              <button
                onClick={() => setIsCreateOpen(false)}
                className="w-8 h-8 rounded-full bg-[#F6F8F7] hover:bg-[#EEF4F1] flex items-center justify-center transition-all text-[#6B8078]"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <form onSubmit={handleCreate} className="space-y-4 py-4">
              <div className="grid grid-cols-2 gap-4">
                {/* Bed ID */}
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Bed ID / Allocation</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. ICU-101"
                    value={newBedId}
                    onChange={(e) => setNewBedId(e.target.value)}
                    className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                </div>

                {/* Service Type */}
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Clinical Category</label>
                  <select
                    value={newType}
                    onChange={(e) => setNewType(e.target.value as MedicalTask["type"])}
                    className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  >
                    <option value="nursing">Nursing Orders</option>
                    <option value="lab-test">Laboratory Test</option>
                    <option value="pharmacy">Pharmacy Delivery</option>
                    <option value="sanitization">Ward Sanitization</option>
                  </select>
                </div>
              </div>

              {/* Task Details */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-[#12463E]">Order specifications / details</label>
                <textarea
                  required
                  placeholder="e.g. Administer 10ml Epinephrine and check telemetry BP levels..."
                  value={newTaskDesc}
                  onChange={(e) => setNewTaskDesc(e.target.value)}
                  className="w-full h-24 p-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all resize-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                {/* Priority */}
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Priority Level</label>
                  <select
                    value={newPriority}
                    onChange={(e) => setNewPriority(e.target.value as MedicalTask["priority"])}
                    className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  >
                    <option value="low">Low Priority</option>
                    <option value="medium">Medium Priority</option>
                    <option value="high">High Priority</option>
                    <option value="emergency">EMERGENCY</option>
                  </select>
                </div>

                {/* Nurse Assignment */}
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Assign Nurse Member</label>
                  <select
                    value={newAssignee}
                    onChange={(e) => setNewAssignee(e.target.value)}
                    className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  >
                    {nursesList.map((n, i) => (
                      <option key={i} value={n}>
                        {n}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Modal Actions */}
              <div className="flex gap-3 border-t border-[#E8ECEB] pt-4 mt-2">
                <button
                  type="button"
                  onClick={() => setIsCreateOpen(false)}
                  className="flex-1 h-11 rounded-xl border border-[#D7E2DC] text-xs font-bold text-[#6B8078] hover:bg-[#F6F8F7] transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 h-11 rounded-xl bg-emerald-600 text-white text-xs font-bold hover:bg-emerald-700 shadow-md shadow-emerald-600/10 transition-all"
                >
                  Dispatch Staff
                </button>
              </div>
            </form>
          </div>
        </>
      )}
    </div>
  )
}
