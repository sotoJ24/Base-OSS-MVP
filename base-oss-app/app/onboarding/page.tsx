"use client"

import type React from "react"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Code2, User, Wrench } from "lucide-react"
import { useRouter } from "next/navigation"

type UserRole = "contributor" | "maintainer" | null

export default function OnboardingPage() {
  const router = useRouter()
  const [step, setStep] = useState<"role" | "profile">("role")
  const [role, setRole] = useState<UserRole>(null)

  const handleRoleSelect = (selectedRole: UserRole) => {
    setRole(selectedRole)
    setStep("profile")
  }

  const handleComplete = () => {
    // TODO: Save user profile data
    console.log("[v0] Onboarding complete, role:", role)
    if (role === "contributor") {
      router.push("/browse")
    } else {
      router.push("/dashboard")
    }
  }

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      <div className="w-full max-w-2xl">
        {/* Logo */}
        <div className="flex items-center justify-center gap-2 mb-8">
          <Code2 className="h-8 w-8 text-primary" />
          <span className="text-2xl font-bold">Base OSS Match</span>
        </div>

        {/* Progress */}
        <div className="flex items-center justify-center gap-2 mb-8">
          <div className={`h-2 w-16 rounded-full ${step === "role" ? "bg-primary" : "bg-muted"}`} />
          <div className={`h-2 w-16 rounded-full ${step === "profile" ? "bg-primary" : "bg-muted"}`} />
        </div>

        {step === "role" ? (
          <Card className="p-8 bg-card border-border">
            <div className="text-center mb-8">
              <h1 className="text-2xl font-bold mb-2">Welcome! Choose Your Role</h1>
              <p className="text-muted-foreground">How would you like to use Base OSS Match?</p>
            </div>

            <div className="grid md:grid-cols-2 gap-4">
              <button
                onClick={() => handleRoleSelect("contributor")}
                className="p-6 rounded-lg border-2 border-border hover:border-primary transition-colors text-left group"
              >
                <div className="h-12 w-12 rounded-lg bg-primary/10 flex items-center justify-center mb-4 group-hover:bg-primary/20 transition-colors">
                  <User className="h-6 w-6 text-primary" />
                </div>
                <h3 className="text-xl font-semibold mb-2">Contributor</h3>
                <p className="text-muted-foreground text-sm leading-relaxed">
                  Find and contribute to Base ecosystem projects that match your skills
                </p>
              </button>

              <button
                onClick={() => handleRoleSelect("maintainer")}
                className="p-6 rounded-lg border-2 border-border hover:border-primary transition-colors text-left group"
              >
                <div className="h-12 w-12 rounded-lg bg-accent/10 flex items-center justify-center mb-4 group-hover:bg-accent/20 transition-colors">
                  <Wrench className="h-6 w-6 text-accent" />
                </div>
                <h3 className="text-xl font-semibold mb-2">Maintainer</h3>
                <p className="text-muted-foreground text-sm leading-relaxed">
                  List your projects and find qualified contributors for your issues
                </p>
              </button>
            </div>
          </Card>
        ) : role === "contributor" ? (
          <ContributorProfileForm onComplete={handleComplete} onBack={() => setStep("role")} />
        ) : (
          <MaintainerProfileForm onComplete={handleComplete} onBack={() => setStep("role")} />
        )}
      </div>
    </div>
  )
}

function ContributorProfileForm({ onComplete, onBack }: { onComplete: () => void; onBack: () => void }) {
  const [formData, setFormData] = useState({
    name: "",
    bio: "",
    techStack: "",
    interests: "",
    experienceLevel: "intermediate",
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    console.log("[v0] Contributor profile:", formData)
    onComplete()
  }

  return (
    <Card className="p-8 bg-card border-border">
      <div className="mb-6">
        <h1 className="text-2xl font-bold mb-2">Set Up Your Profile</h1>
        <p className="text-muted-foreground">Tell us about your skills so we can match you with the right projects</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="space-y-2">
          <Label htmlFor="name">Display Name</Label>
          <Input
            id="name"
            placeholder="John Doe"
            value={formData.name}
            onChange={(e: { target: { value: any } }) => setFormData({ ...formData, name: e.target.value })}
            required
            className="bg-background"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="bio">Bio</Label>
          <textarea
            id="bio"
            placeholder="Tell us about yourself..."
            value={formData.bio}
            onChange={(e) => setFormData({ ...formData, bio: e.target.value })}
            className="w-full min-h-24 px-3 py-2 rounded-md border border-input bg-background text-foreground"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="techStack">Tech Stack</Label>
          <Input
            id="techStack"
            placeholder="React, TypeScript, Solidity, Node.js"
            value={formData.techStack}
            onChange={(e: { target: { value: any } }) => setFormData({ ...formData, techStack: e.target.value })}
            required
            className="bg-background"
          />
          <p className="text-xs text-muted-foreground">Comma-separated list of technologies you work with</p>
        </div>

        <div className="space-y-2">
          <Label htmlFor="interests">Interests & Topics</Label>
          <Input
            id="interests"
            placeholder="AI, DeFi, NFTs, Gaming"
            value={formData.interests}
            onChange={(e: { target: { value: any } }) => setFormData({ ...formData, interests: e.target.value })}
            className="bg-background"
          />
          <p className="text-xs text-muted-foreground">What types of projects interest you?</p>
        </div>

        <div className="space-y-2">
          <Label htmlFor="experience">Experience Level</Label>
          <select
            id="experience"
            value={formData.experienceLevel}
            onChange={(e) => setFormData({ ...formData, experienceLevel: e.target.value })}
            className="w-full px-3 py-2 rounded-md border border-input bg-background text-foreground"
          >
            <option value="beginner">Beginner</option>
            <option value="intermediate">Intermediate</option>
            <option value="advanced">Advanced</option>
          </select>
        </div>

        <div className="flex gap-4 pt-4">
          <Button type="button" variant="outline" onClick={onBack} className="bg-transparent">
            Back
          </Button>
          <Button type="submit" className="flex-1">
            Complete Setup
          </Button>
        </div>
      </form>
    </Card>
  )
}

function MaintainerProfileForm({ onComplete, onBack }: { onComplete: () => void; onBack: () => void }) {
  const [formData, setFormData] = useState({
    name: "",
    organization: "",
    bio: "",
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    console.log("[v0] Maintainer profile:", formData)
    onComplete()
  }

  return (
    <Card className="p-8 bg-card border-border">
      <div className="mb-6">
        <h1 className="text-2xl font-bold mb-2">Set Up Your Profile</h1>
        <p className="text-muted-foreground">Tell us about yourself and your projects</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="space-y-2">
          <Label htmlFor="name">Display Name</Label>
          <Input
            id="name"
            placeholder="John Doe"
            value={formData.name}
            onChange={(e: { target: { value: any } }) => setFormData({ ...formData, name: e.target.value })}
            required
            className="bg-background"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="organization">Organization (Optional)</Label>
          <Input
            id="organization"
            placeholder="Your Company or Project"
            value={formData.organization}
            onChange={(e: { target: { value: any } }) => setFormData({ ...formData, organization: e.target.value })}
            className="bg-background"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="bio">Bio</Label>
          <textarea
            id="bio"
            placeholder="Tell us about your projects..."
            value={formData.bio}
            onChange={(e) => setFormData({ ...formData, bio: e.target.value })}
            className="w-full min-h-24 px-3 py-2 rounded-md border border-input bg-background text-foreground"
          />
        </div>

        <div className="flex gap-4 pt-4">
          <Button type="button" variant="outline" onClick={onBack} className="bg-transparent">
            Back
          </Button>
          <Button type="submit" className="flex-1">
            Complete Setup
          </Button>
        </div>
      </form>
    </Card>
  )
}
