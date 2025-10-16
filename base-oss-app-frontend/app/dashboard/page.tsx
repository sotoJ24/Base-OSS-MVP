"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Code2, User, Plus, GitPullRequest, AlertCircle, CheckCircle, Clock } from "lucide-react"
import Link from "next/link"

type UserRole = "contributor" | "maintainer"

export default function DashboardPage() {
  // TODO: Get actual user role from auth context
  const [userRole] = useState<UserRole>("contributor")

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b border-border sticky top-0 bg-background/95 backdrop-blur z-10">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2">
            <Code2 className="h-6 w-6 text-primary" />
            <span className="text-xl font-semibold">Base OSS Match</span>
          </Link>
          <div className="flex items-center gap-4">
            <Link href="/browse">
              <Button variant="ghost" size="sm">
                Browse
              </Button>
            </Link>
            <Button variant="outline" size="sm" className="gap-2 bg-transparent">
              <User className="h-4 w-4" />
              Profile
            </Button>
          </div>
        </div>
      </header>

      {userRole === "contributor" ? <ContributorDashboard /> : <MaintainerDashboard />}
    </div>
  )
}

function ContributorDashboard() {
  const appliedIssues = [
    {
      id: 1,
      title: "Fix UI responsiveness on mobile",
      repo: "base-defi-protocol",
      status: "pending",
      appliedDate: "2 days ago",
    },
    {
      id: 2,
      title: "Add unit tests for staking contract",
      repo: "nft-marketplace",
      status: "accepted",
      appliedDate: "5 days ago",
    },
    {
      id: 3,
      title: "Implement dark mode",
      repo: "gaming-sdk",
      status: "in-progress",
      appliedDate: "1 week ago",
    },
  ]

  const notifications = [
    {
      id: 1,
      message: "Your application for 'Fix UI responsiveness' was accepted!",
      time: "1 hour ago",
      type: "success",
    },
    {
      id: 2,
      message: "New issue matching your skills: 'Add TypeScript support'",
      time: "3 hours ago",
      type: "info",
    },
    {
      id: 3,
      message: "Maintainer commented on your PR for 'Add unit tests'",
      time: "1 day ago",
      type: "info",
    },
  ]

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Welcome Section */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Welcome back, Contributor!</h1>
        <p className="text-muted-foreground">Track your applications and discover new opportunities</p>
      </div>

      {/* Stats */}
      <div className="grid md:grid-cols-4 gap-4 mb-8">
        <Card className="p-6 bg-card border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground mb-1">Applied</p>
              <p className="text-2xl font-bold">3</p>
            </div>
            <AlertCircle className="h-8 w-8 text-muted-foreground" />
          </div>
        </Card>

        <Card className="p-6 bg-card border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground mb-1">Accepted</p>
              <p className="text-2xl font-bold">1</p>
            </div>
            <CheckCircle className="h-8 w-8 text-chart-3" />
          </div>
        </Card>

        <Card className="p-6 bg-card border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground mb-1">In Progress</p>
              <p className="text-2xl font-bold">1</p>
            </div>
            <Clock className="h-8 w-8 text-primary" />
          </div>
        </Card>

        <Card className="p-6 bg-card border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground mb-1">Completed</p>
              <p className="text-2xl font-bold">5</p>
            </div>
            <GitPullRequest className="h-8 w-8 text-accent" />
          </div>
        </Card>
      </div>

      <div className="grid lg:grid-cols-3 gap-6">
        {/* Applied Issues */}
        <div className="lg:col-span-2">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-2xl font-bold">Your Applications</h2>
            <Link href="/browse">
              <Button size="sm">Browse More</Button>
            </Link>
          </div>

          <div className="space-y-4">
            {appliedIssues.map((issue) => (
              <Card key={issue.id} className="p-6 bg-card border-border">
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <h3 className="text-lg font-semibold mb-1">{issue.title}</h3>
                    <p className="text-sm text-muted-foreground">{issue.repo}</p>
                  </div>
                  <Badge
                    variant={
                      issue.status === "accepted" ? "default" : issue.status === "in-progress" ? "secondary" : "outline"
                    }
                  >
                    {issue.status}
                  </Badge>
                </div>
                <div className="flex items-center justify-between">
                  <p className="text-sm text-muted-foreground">Applied {issue.appliedDate}</p>
                  <Button variant="outline" size="sm" className="bg-transparent">
                    View Details
                  </Button>
                </div>
              </Card>
            ))}
          </div>
        </div>

        {/* Notifications */}
        <aside>
          <h2 className="text-2xl font-bold mb-4">Notifications</h2>
          <Card className="p-4 bg-card border-border">
            <div className="space-y-4">
              {notifications.map((notification) => (
                <div key={notification.id} className="pb-4 border-b border-border last:border-0 last:pb-0">
                  <p className="text-sm leading-relaxed mb-2">{notification.message}</p>
                  <p className="text-xs text-muted-foreground">{notification.time}</p>
                </div>
              ))}
            </div>
          </Card>
        </aside>
      </div>
    </div>
  )
}

function MaintainerDashboard() {
  const repos = [
    {
      id: 1,
      name: "base-defi-protocol",
      openIssues: 12,
      pendingApplicants: 5,
      activeContributors: 3,
    },
    {
      id: 2,
      name: "nft-marketplace",
      openIssues: 8,
      pendingApplicants: 2,
      activeContributors: 2,
    },
  ]

  const pendingApplications = [
    {
      id: 1,
      contributor: "alice_dev",
      issue: "Fix UI responsiveness on mobile",
      repo: "base-defi-protocol",
      appliedDate: "2 hours ago",
      message: "I have 3 years of experience with responsive design...",
    },
    {
      id: 2,
      contributor: "bob_builder",
      issue: "Add unit tests for staking contract",
      repo: "base-defi-protocol",
      appliedDate: "5 hours ago",
      message: "I'm familiar with Hardhat testing framework...",
    },
    {
      id: 3,
      contributor: "charlie_code",
      issue: "Implement gas optimization",
      repo: "nft-marketplace",
      appliedDate: "1 day ago",
      message: "I've optimized several smart contracts before...",
    },
  ]

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Welcome Section */}
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold mb-2">Maintainer Dashboard</h1>
          <p className="text-muted-foreground">Manage your projects and review applications</p>
        </div>
        <Button className="gap-2">
          <Plus className="h-4 w-4" />
          Add Repository
        </Button>
      </div>

      {/* Your Repositories */}
      <div className="mb-8">
        <h2 className="text-2xl font-bold mb-4">Your Repositories</h2>
        <div className="grid md:grid-cols-2 gap-4">
          {repos.map((repo) => (
            <Card key={repo.id} className="p-6 bg-card border-border">
              <h3 className="text-xl font-semibold mb-4">{repo.name}</h3>
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <p className="text-2xl font-bold">{repo.openIssues}</p>
                  <p className="text-sm text-muted-foreground">Open Issues</p>
                </div>
                <div>
                  <p className="text-2xl font-bold text-primary">{repo.pendingApplicants}</p>
                  <p className="text-sm text-muted-foreground">Pending</p>
                </div>
                <div>
                  <p className="text-2xl font-bold text-chart-3">{repo.activeContributors}</p>
                  <p className="text-sm text-muted-foreground">Active</p>
                </div>
              </div>
              <Button variant="outline" className="w-full mt-4 bg-transparent">
                Manage Repository
              </Button>
            </Card>
          ))}
        </div>
      </div>

      {/* Pending Applications */}
      <div>
        <h2 className="text-2xl font-bold mb-4">Pending Applications</h2>
        <div className="space-y-4">
          {pendingApplications.map((application) => (
            <Card key={application.id} className="p-6 bg-card border-border">
              <div className="flex items-start justify-between mb-4">
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <User className="h-4 w-4 text-muted-foreground" />
                    <span className="font-semibold">{application.contributor}</span>
                  </div>
                  <h3 className="text-lg font-semibold mb-1">{application.issue}</h3>
                  <p className="text-sm text-muted-foreground">
                    {application.repo} • Applied {application.appliedDate}
                  </p>
                </div>
              </div>

              <p className="text-muted-foreground mb-4 leading-relaxed">{application.message}</p>

              <div className="flex gap-3">
                <Button size="sm" className="flex-1">
                  Accept
                </Button>
                <Button variant="outline" size="sm" className="flex-1 bg-transparent">
                  View Profile
                </Button>
                <Button variant="outline" size="sm" className="bg-transparent">
                  Decline
                </Button>
              </div>
            </Card>
          ))}
        </div>
      </div>
    </div>
  )
}
