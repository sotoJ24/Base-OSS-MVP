"use client"

import { SetStateAction, useState } from "react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Code2, Search, Star, GitFork, AlertCircle, User } from "lucide-react"
import Link from "next/link"

// Mock data for demonstration
const mockRepos = [
  {
    id: 1,
    name: "base-defi-protocol",
    description: "Decentralized finance protocol built on Base with advanced yield strategies",
    owner: "BaseDAO",
    stars: 234,
    forks: 45,
    techStack: ["Solidity", "TypeScript", "React"],
    topics: ["DeFi", "Smart Contracts"],
    openIssues: 12,
    goodFirstIssues: 3,
  },
  {
    id: 2,
    name: "nft-marketplace",
    description: "Full-featured NFT marketplace with gasless transactions on Base",
    owner: "BaseNFT",
    stars: 189,
    forks: 32,
    techStack: ["Solidity", "Next.js", "Tailwind"],
    topics: ["NFTs", "Marketplace"],
    openIssues: 8,
    goodFirstIssues: 2,
  },
  {
    id: 3,
    name: "ai-agent-framework",
    description: "Framework for building autonomous AI agents on Base blockchain",
    owner: "BaseAI",
    stars: 456,
    forks: 78,
    techStack: ["Python", "TypeScript", "Solidity"],
    topics: ["AI", "Agents"],
    openIssues: 15,
    goodFirstIssues: 5,
  },
  {
    id: 4,
    name: "gaming-sdk",
    description: "SDK for integrating Base blockchain into gaming applications",
    owner: "BaseGaming",
    stars: 312,
    forks: 56,
    techStack: ["TypeScript", "Unity", "Solidity"],
    topics: ["Gaming", "SDK"],
    openIssues: 10,
    goodFirstIssues: 4,
  },
]

const allTechStack = ["Solidity", "TypeScript", "React", "Next.js", "Python", "Tailwind", "Unity"]
const allTopics = ["DeFi", "NFTs", "AI", "Gaming", "Smart Contracts", "Marketplace", "Agents", "SDK"]

export default function BrowsePage() {
  const [searchQuery, setSearchQuery] = useState("")
  const [selectedTech, setSelectedTech] = useState<string[]>([])
  const [selectedTopics, setSelectedTopics] = useState<string[]>([])

  const toggleFilter = (item: string, list: string[], setter: (list: string[]) => void) => {
    if (list.includes(item)) {
      setter(list.filter((i) => i !== item))
    } else {
      setter([...list, item])
    }
  }

  const filteredRepos = mockRepos.filter((repo) => {
    const matchesSearch =
      searchQuery === "" ||
      repo.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      repo.description.toLowerCase().includes(searchQuery.toLowerCase())

    const matchesTech = selectedTech.length === 0 || selectedTech.some((tech) => repo.techStack.includes(tech))

    const matchesTopics = selectedTopics.length === 0 || selectedTopics.some((topic) => repo.topics.includes(topic))

    return matchesSearch && matchesTech && matchesTopics
  })

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
        {/* Page Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2">Browse Projects</h1>
          <p className="text-muted-foreground">Discover Base ecosystem projects that match your skills</p>
        </div>

        <div className="grid lg:grid-cols-4 gap-6">
          {/* Filters Sidebar */}
          <aside className="lg:col-span-1">
            <Card className="p-6 bg-card border-border sticky top-24">
              <h2 className="font-semibold mb-4">Filters</h2>

              {/* Search */}
              <div className="mb-6">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    placeholder="Search projects..."
                    value={searchQuery}
                    onChange={(e: { target: { value: SetStateAction<string> } }) => setSearchQuery(e.target.value)}
                    className="pl-9 bg-background"
                  />
                </div>
              </div>

              {/* Tech Stack Filter */}
              <div className="mb-6">
                <h3 className="text-sm font-medium mb-3">Tech Stack</h3>
                <div className="flex flex-wrap gap-2">
                  {allTechStack.map((tech) => (
                    <Badge
                      key={tech}
                      variant={selectedTech.includes(tech) ? "default" : "outline"}
                      className="cursor-pointer"
                      onClick={() => toggleFilter(tech, selectedTech, setSelectedTech)}
                    >
                      {tech}
                    </Badge>
                  ))}
                </div>
              </div>

              {/* Topics Filter */}
              <div>
                <h3 className="text-sm font-medium mb-3">Topics</h3>
                <div className="flex flex-wrap gap-2">
                  {allTopics.map((topic) => (
                    <Badge
                      key={topic}
                      variant={selectedTopics.includes(topic) ? "default" : "outline"}
                      className="cursor-pointer"
                      onClick={() => toggleFilter(topic, selectedTopics, setSelectedTopics)}
                    >
                      {topic}
                    </Badge>
                  ))}
                </div>
              </div>

              {/* Clear Filters */}
              {(selectedTech.length > 0 || selectedTopics.length > 0 || searchQuery) && (
                <Button
                  variant="ghost"
                  size="sm"
                  className="w-full mt-4"
                  onClick={() => {
                    setSelectedTech([])
                    setSelectedTopics([])
                    setSearchQuery("")
                  }}
                >
                  Clear All Filters
                </Button>
              )}
            </Card>
          </aside>

          {/* Repos List */}
          <div className="lg:col-span-3">
            <div className="mb-4 flex items-center justify-between">
              <p className="text-sm text-muted-foreground">
                {filteredRepos.length} {filteredRepos.length === 1 ? "project" : "projects"} found
              </p>
            </div>

            <div className="space-y-4">
              {filteredRepos.map((repo) => (
                <Link key={repo.id} href={`/repo/${repo.id}`}>
                  <Card className="p-6 bg-card border-border hover:border-primary transition-colors cursor-pointer">
                    <div className="flex items-start justify-between mb-3">
                      <div>
                        <h3 className="text-xl font-semibold mb-1">{repo.name}</h3>
                        <p className="text-sm text-muted-foreground">by {repo.owner}</p>
                      </div>
                      <div className="flex items-center gap-4 text-sm text-muted-foreground">
                        <div className="flex items-center gap-1">
                          <Star className="h-4 w-4" />
                          {repo.stars}
                        </div>
                        <div className="flex items-center gap-1">
                          <GitFork className="h-4 w-4" />
                          {repo.forks}
                        </div>
                      </div>
                    </div>

                    <p className="text-muted-foreground mb-4 leading-relaxed">{repo.description}</p>

                    <div className="flex flex-wrap gap-2 mb-4">
                      {repo.techStack.map((tech) => (
                        <Badge key={tech} variant="secondary">
                          {tech}
                        </Badge>
                      ))}
                      {repo.topics.map((topic) => (
                        <Badge key={topic} variant="outline">
                          {topic}
                        </Badge>
                      ))}
                    </div>

                    <div className="flex items-center gap-4 text-sm">
                      <div className="flex items-center gap-1 text-muted-foreground">
                        <AlertCircle className="h-4 w-4" />
                        {repo.openIssues} open issues
                      </div>
                      {repo.goodFirstIssues > 0 && (
                        <Badge variant="default" className="bg-chart-3 text-chart-3-foreground">
                          {repo.goodFirstIssues} good first issues
                        </Badge>
                      )}
                    </div>
                  </Card>
                </Link>
              ))}

              {filteredRepos.length === 0 && (
                <Card className="p-12 bg-card border-border text-center">
                  <p className="text-muted-foreground">No projects found matching your filters</p>
                  <Button
                    variant="outline"
                    className="mt-4 bg-transparent"
                    onClick={() => {
                      setSelectedTech([])
                      setSelectedTopics([])
                      setSearchQuery("")
                    }}
                  >
                    Clear Filters
                  </Button>
                </Card>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
