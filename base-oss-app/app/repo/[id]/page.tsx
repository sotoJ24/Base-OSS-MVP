"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Code2, Star, GitFork, ExternalLink, User, AlertCircle, Clock } from "lucide-react"
import Link from "next/link"
import { useParams } from "next/navigation"

// Mock data
const mockRepo = {
  id: 1,
  name: "base-defi-protocol",
  description: "Decentralized finance protocol built on Base with advanced yield strategies",
  owner: "BaseDAO",
  stars: 234,
  forks: 45,
  techStack: ["Solidity", "TypeScript", "React"],
  topics: ["DeFi", "Smart Contracts"],
  githubUrl: "https://github.com/basedao/base-defi-protocol",
  website: "https://basedefi.example.com",
  readme:
    "A comprehensive DeFi protocol that enables users to maximize their yields through automated strategies on the Base blockchain. Features include liquidity pools, yield farming, and governance.",
}

const mockIssues = [
  {
    id: 1,
    title: "Add support for new token pairs",
    description: "We need to add support for USDC/ETH and DAI/ETH pairs in the liquidity pool contract.",
    difficulty: "intermediate",
    status: "open",
    labels: ["enhancement", "smart-contracts"],
    applicants: 2,
    estimatedTime: "2-3 days",
    isGoodFirstIssue: false,
  },
  {
    id: 2,
    title: "Fix UI responsiveness on mobile",
    description: "The dashboard doesn't display correctly on mobile devices. Need to improve responsive design.",
    difficulty: "beginner",
    status: "open",
    labels: ["bug", "frontend", "good-first-issue"],
    applicants: 0,
    estimatedTime: "1 day",
    isGoodFirstIssue: true,
  },
  {
    id: 3,
    title: "Implement gas optimization for swap function",
    description: "The swap function is consuming too much gas. Need to optimize the contract logic.",
    difficulty: "advanced",
    status: "open",
    labels: ["optimization", "smart-contracts"],
    applicants: 1,
    estimatedTime: "3-5 days",
    isGoodFirstIssue: false,
  },
  {
    id: 4,
    title: "Add unit tests for staking contract",
    description: "Write comprehensive unit tests for the staking contract to ensure security.",
    difficulty: "intermediate",
    status: "open",
    labels: ["testing", "good-first-issue"],
    applicants: 0,
    estimatedTime: "2 days",
    isGoodFirstIssue: true,
  },
]

export default function RepoDetailPage() {
  const params = useParams()
  const [selectedIssue, setSelectedIssue] = useState<number | null>(null)
  const [showApplicationModal, setShowApplicationModal] = useState(false)

  const handleApply = (issueId: number) => {
    setSelectedIssue(issueId)
    setShowApplicationModal(true)
  }

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
            <Link href="/dashboard">
              <Button variant="ghost" size="sm">
                Dashboard
              </Button>
            </Link>
            <Button variant="outline" size="sm" className="gap-2 bg-transparent">
              <User className="h-4 w-4" />
              Profile
            </Button>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8">
        {/* Repo Header */}
        <Card className="p-6 bg-card border-border mb-6">
          <div className="flex items-start justify-between mb-4">
            <div>
              <h1 className="text-3xl font-bold mb-2">{mockRepo.name}</h1>
              <p className="text-muted-foreground">by {mockRepo.owner}</p>
            </div>
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-1 text-muted-foreground">
                <Star className="h-5 w-5" />
                {mockRepo.stars}
              </div>
              <div className="flex items-center gap-1 text-muted-foreground">
                <GitFork className="h-5 w-5" />
                {mockRepo.forks}
              </div>
            </div>
          </div>

          <p className="text-lg mb-4 leading-relaxed">{mockRepo.description}</p>

          <div className="flex flex-wrap gap-2 mb-4">
            {mockRepo.techStack.map((tech) => (
              <Badge key={tech} variant="secondary">
                {tech}
              </Badge>
            ))}
            {mockRepo.topics.map((topic) => (
              <Badge key={topic} variant="outline">
                {topic}
              </Badge>
            ))}
          </div>

          <div className="flex gap-3">
            <Button variant="outline" className="gap-2 bg-transparent" asChild>
              <a href={mockRepo.githubUrl} target="_blank" rel="noopener noreferrer">
                <ExternalLink className="h-4 w-4" />
                View on GitHub
              </a>
            </Button>
            {mockRepo.website && (
              <Button variant="outline" className="gap-2 bg-transparent" asChild>
                <a href={mockRepo.website} target="_blank" rel="noopener noreferrer">
                  <ExternalLink className="h-4 w-4" />
                  Website
                </a>
              </Button>
            )}
          </div>
        </Card>

        <div className="grid lg:grid-cols-3 gap-6">
          {/* About Section */}
          <aside className="lg:col-span-1">
            <Card className="p-6 bg-card border-border">
              <h2 className="font-semibold mb-4">About</h2>
              <p className="text-sm text-muted-foreground leading-relaxed">{mockRepo.readme}</p>
            </Card>
          </aside>

          {/* Issues Section */}
          <div className="lg:col-span-2">
            <div className="mb-4">
              <h2 className="text-2xl font-bold mb-2">Open Issues</h2>
              <p className="text-muted-foreground">Apply to issues that match your skills</p>
            </div>

            <div className="space-y-4">
              {mockIssues.map((issue) => (
                <Card key={issue.id} className="p-6 bg-card border-border">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <h3 className="text-lg font-semibold">{issue.title}</h3>
                        {issue.isGoodFirstIssue && (
                          <Badge variant="default" className="bg-chart-3 text-chart-3-foreground">
                            Good First Issue
                          </Badge>
                        )}
                      </div>
                      <p className="text-muted-foreground mb-3 leading-relaxed">{issue.description}</p>
                    </div>
                  </div>

                  <div className="flex flex-wrap gap-2 mb-4">
                    {issue.labels.map((label) => (
                      <Badge key={label} variant="outline" className="text-xs">
                        {label}
                      </Badge>
                    ))}
                  </div>

                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4 text-sm text-muted-foreground">
                      <div className="flex items-center gap-1">
                        <AlertCircle className="h-4 w-4" />
                        {issue.difficulty}
                      </div>
                      <div className="flex items-center gap-1">
                        <Clock className="h-4 w-4" />
                        {issue.estimatedTime}
                      </div>
                      <div className="flex items-center gap-1">
                        <User className="h-4 w-4" />
                        {issue.applicants} applicants
                      </div>
                    </div>
                    <Button onClick={() => handleApply(issue.id)} size="sm">
                      Apply
                    </Button>
                  </div>
                </Card>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Application Modal */}
      {showApplicationModal && (
        <div className="fixed inset-0 bg-background/80 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <Card className="w-full max-w-md p-6 bg-card border-border">
            <h2 className="text-2xl font-bold mb-4">Apply to Issue</h2>
            <p className="text-muted-foreground mb-6">
              Tell the maintainer why you're a good fit for this issue and your approach to solving it.
            </p>

            <form
              onSubmit={(e) => {
                e.preventDefault()
                console.log("[v0] Application submitted for issue:", selectedIssue)
                setShowApplicationModal(false)
                // TODO: Submit application
              }}
              className="space-y-4"
            >
              <div>
                <label htmlFor="message" className="block text-sm font-medium mb-2">
                  Application Message
                </label>
                <textarea
                  id="message"
                  placeholder="Explain your experience and approach..."
                  className="w-full min-h-32 px-3 py-2 rounded-md border border-input bg-background text-foreground"
                  required
                />
              </div>

              <div className="flex gap-3">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => setShowApplicationModal(false)}
                  className="flex-1 bg-transparent"
                >
                  Cancel
                </Button>
                <Button type="submit" className="flex-1">
                  Submit Application
                </Button>
              </div>
            </form>
          </Card>
        </div>
      )}
    </div>
  )
}
