# ===============================================================================================================================
# The idea with this somewhat complicated process is to end up with the smallest image we can get to run in production
# Ideally, we end up with a container image that _only_ contains what we need to run, nothing else
# Smaller containers are better because they're smaller to store and easier to move around
# ===============================================================================================================================

# ===============================================================================================================================
# Create an image that will be used to build the React app
# This image is temporary and most of it will be discarded as we don't want to have all this stuff in production
# ===============================================================================================================================
FROM node:12-alpine AS build
WORKDIR /app

# Copy the package file and lock file so we can build the app consistently
COPY package.json yarn.lock ./

# Copy over the source code and public assets to prepare for a build
COPY src ./src
COPY public ./public

# Run the Yarn install to pull in all of our dependencies, including build-time dependencies
RUN yarn install --silent

# The build requires some arguments that must be passed in during build time
ARG REACT_APP_OKTA_URL
ARG REACT_APP_CLIENT_ID
ARG REACT_APP_URQL_URL

# Build the application, which will end up in the /app/build directory
RUN yarn react-scripts build


# ============================================================================================================
# Now, create an image that just contains the production dependencies
# The reason we create this image is because production dependencies should change much less frequently than 
# your code. Which means this image will just be reused, saving lots of time _not_ rebuilding node_modules
# ============================================================================================================
FROM node:12-alpine AS deps
WORKDIR /app

# Copy over the package and lock files
COPY package.json yarn.lock ./

# Tell Yarn to build a node_module with just the production dependencies
RUN yarn install --production --silent


# ============================================================================================================
# Now, create a new fresh image and only copy what we need to run this in production
# ============================================================================================================
FROM node:12-alpine
WORKDIR /app

# Copy the built application from the build image
COPY --from=build /app/build ./

# Copy the production dependencies from the deps image
# COPY --from=deps /app/node_modules ./node_modules/

# COPY public ./public
# COPY public ./public

# Copy the package file we don't need the lock file anymore
# COPY package.json ./

RUN yarn global add serve

# Start the React app when the image launches
CMD [ "serve", "-p", "8000", "." ]
EXPOSE 8000
