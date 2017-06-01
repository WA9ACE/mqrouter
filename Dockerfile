FROM ruby:2.2.1

RUN mkdir -p /usr/src/app

WORKDIR /usr/src/app

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
COPY mqrouter.gemspec /usr/src/app/
COPY lib/mqrouter/version.rb /usr/src/app/lib/mqrouter/
RUN gem install bundler
RUN bundle install

ADD . /usr/src/app
